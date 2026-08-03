require "test_helper"

module Journeybook
  class PageTemplateRegistryTest < ActiveSupport::TestCase
    test "registers templates by normalized key" do
      registry = PageTemplateRegistry.new

      template = registry.register("blog post", name: "Blog post", page_type: "blog_post", markdown: "{{ article_hero }}")

      assert_equal :blog_post, template.key
      assert_equal "Blog post", registry.fetch(:blog_post).name
      assert_equal "blog_post", registry.fetch(:blog_post).page_type
      assert_equal "{{ article_hero }}", registry.fetch(:blog_post).markdown
    end

    test "filters templates by site key" do
      marketing = Site.new(name: "Marketing", key: "marketing", host: "example.test", path_prefix: "/")
      registry = PageTemplateRegistry.new
      registry.register(:blog_post, sites: %i[marketing], markdown: "{{ article_hero }}")
      registry.register(:knowledge_base, sites: %i[docs], markdown: "{{ text text=\"Article\" }}")
      registry.register(:landing_page, markdown: "{{ hero }}")

      assert_equal %i[blog_post landing_page], registry.for_site(marketing).map(&:key)
    end

    test "returns template path metadata" do
      registry = PageTemplateRegistry.new
      registry.register(:blog_post, path_prefix: "/blog", path_hint: "/blog/your-post-title", markdown: "{{ article_hero }}")

      template = registry.fetch(:blog_post)

      assert_equal "/blog", template.path_prefix
      assert_equal "/blog/your-post-title", template.path_hint
    end
  end
end
