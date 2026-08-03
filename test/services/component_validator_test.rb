require "test_helper"

module Journeybook
  class ComponentValidatorTest < ActiveSupport::TestCase
    setup do
      @site = Site.create!(name: "Main", host: "example.test", default_locale: "en")
      @registry = ComponentRegistry.new
      @registry.register(:hero, String, props: {
        title: "Headline",
        image_url: { type: :image, required: false },
        href: { type: :url, required: false }
      })
    end

    test "accepts registered components with valid props" do
      page = build_page('{{ hero title="Hello" image_url="https://cdn.example.test/hero.jpg" href="/#contact" }}')

      assert_empty ComponentValidator.new(registry: @registry).errors_for(page)
    end

    test "reports unknown components and props" do
      page = build_page('{{ missing title="Hello" }} {{ hero title="Hello" extra="value" }}')

      errors = ComponentValidator.new(registry: @registry).errors_for(page)

      assert_includes errors, "Component 1 (missing) is not registered for this site."
      assert_includes errors, "Component 2 (hero) has an unknown prop: extra."
    end

    test "reports missing required and invalid typed props" do
      page = build_page('{{ hero title="" image_url="/hero.jpg" href="mailto:team@example.test" }}')

      errors = ComponentValidator.new(registry: @registry).errors_for(page)

      assert_includes errors, "Component 1 (hero) is missing required prop: title."
      assert_includes errors, "Component 1 (hero) has an invalid image prop: image_url."
      assert_includes errors, "Component 1 (hero) has an invalid url prop: href."
    end

    test "validates collection item schemas" do
      @registry.register(:feature_grid, String, props: {
        items: { type: :collection, min: 1, max: 2, item: { title: "Feature title", href: { type: :url, required: false } } }
      })
      page = build_page(%({{ feature_grid items='[{"title":"One","href":"/one"},{"unknown":"value"},{"title":"Three"}]' }}))

      errors = ComponentValidator.new(registry: @registry).errors_for(page)

      assert_includes errors, "Component 1 (feature_grid) allows at most 2 items item(s)."
      assert_includes errors, "Component 1 (feature_grid) items item 2 has an unknown prop: unknown."
      assert_includes errors, "Component 1 (feature_grid) items item 2 is missing required prop: title."
    end

    test "rejects values outside select options" do
      @registry.register(:feature_card, String, props: {
        gradient: { type: :select, options: %w[sunset forest stone] }
      })
      page = build_page('{{ feature_card gradient="blue" }}')

      errors = ComponentValidator.new(registry: @registry).errors_for(page)

      assert_includes errors, "Component 1 (feature_card) has an invalid select prop: gradient."
    end

    private

    def build_page(markdown)
      @site.pages.build(title: "Home", slug: "home", path: "/", markdown: markdown, status: "draft", locale: "en")
    end
  end
end
