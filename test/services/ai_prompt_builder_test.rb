require "test_helper"

module Journeybook
  module Ai
    class PromptBuilderTest < ActiveSupport::TestCase
      test "includes user prompt and component schema" do
        registry = ComponentRegistry.new
        registry.register(:hero, String, description: "Landing hero", props: { title: "Headline", subtitle: "Support copy" })
        site = Site.new(name: "Marketing", key: "marketing", host: "example.test", path_prefix: "/", layout: "application")

        prompt = PromptBuilder.new(components: registry, site: site).build(user_prompt: "Build a homepage")

        assert_includes prompt, "Build a homepage"
        assert_includes prompt, "Marketing"
        assert_includes prompt, "hero"
        assert_includes prompt, "Landing hero"
        assert_includes prompt, 'title="..."'
      end

      test "includes selected style instructions" do
        prompt = PromptBuilder.new(components: ComponentRegistry.new, style_prompt: "Use a concise editorial tone.").build(user_prompt: "Build an article")

        assert_includes prompt, "Style instructions:"
        assert_includes prompt, "Use a concise editorial tone."
      end

      test "includes image library entries and image rules" do
        original_public_base_url = Journeybook.configuration.s3_public_base_url
        Journeybook.configuration.s3_public_base_url = "https://cdn.example.test"
        asset = MediaAsset.create!(title: "Founder portrait", alt_text: "Portrait of the founder", tags: "team, portrait", storage_key: "journeybook/media/founder.jpg", original_filename: "founder.jpg", content_type: "image/jpeg", byte_size: 12)

        prompt = PromptBuilder.new(components: ComponentRegistry.new, media_assets: [ asset ]).build(user_prompt: "Build an about page")

        assert_includes prompt, "Available image library:"
        assert_includes prompt, "Founder portrait"
        assert_includes prompt, "Portrait of the founder"
        assert_includes prompt, "https://cdn.example.test/journeybook/media/founder.jpg"
        assert_includes prompt, "Do not invent image URLs."
        assert_includes prompt, "Do not output raw Markdown image syntax."
      ensure
        Journeybook.configuration.s3_public_base_url = original_public_base_url
      end

    test "instructs ai to write page content only as components" do
        registry = ComponentRegistry.new
        registry.register(:hero, String, props: { title: "Headline" })

        prompt = PromptBuilder.new(components: registry).build(user_prompt: "Build a homepage")

        assert_includes prompt, "Use component tags only for page content."
        assert_includes prompt, "Do not write Markdown headings, paragraphs, lists, links, raw HTML, or standalone text outside component tags."
        assert_includes prompt, "The only allowed non-component content is frontmatter"
        assert_includes prompt, "Copy/text may appear inside component prop values."
      assert_not_includes prompt, "Use normal Markdown for headings, paragraphs, lists, and links."
    end

    test "includes collection schemas and JSON examples" do
      registry = ComponentRegistry.new
      registry.register(:feature_grid, String, props: {
        items: { type: :collection, min: 1, max: 4, item: { title: "Feature title", gradient: { type: :select, options: %w[sunset forest] } } }
      })

      prompt = PromptBuilder.new(components: registry).build(user_prompt: "Build a homepage")

      assert_includes prompt, "items (collection, 1-4 items): title (short_text), gradient (select: sunset, forest)"
      assert_includes prompt, %(items='[{"title":"...","gradient":"sunset"}]')
    end

    test "restricts the component catalog to the selected template" do
      registry = ComponentRegistry.new
      registry.register(:article_hero, String, description: "Article header")
      registry.register(:text, String, description: "Longform content", props: { text: { type: :long_text } })
      registry.register(:cta_panel, String, description: "CTA", props: { headline: "Headline" })
      template = PageTemplateRegistry::Template.new(:blog_post, {
        name: "Blog post",
        page_type: "blog_post",
        markdown: "{{ article_hero }}\n\n{{ text text=\"Start here\" }}"
      })

      prompt = PromptBuilder.new(components: registry, template: template).build(user_prompt: "Write about onboarding")

      assert_includes prompt, "Template: Blog post"
      assert_includes prompt, "Editorial purpose:"
      assert_includes prompt, "Use only the template components, in exactly this order"
      assert_includes prompt, "article_hero"
      assert_includes prompt, "Longform content"
      refute_includes prompt, "Description: CTA"
    end
    end
  end
end
