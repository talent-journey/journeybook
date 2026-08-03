require "test_helper"

module Journeybook
  class ComponentRegistryTest < ActiveSupport::TestCase
    class HeroComponent; end

    test "registers and fetches components by normalized name" do
      registry = ComponentRegistry.new

      registry.register("hero-card", HeroComponent)

      assert_equal HeroComponent, registry.fetch(:hero_card)
    end

    test "raises for unknown components" do
      registry = ComponentRegistry.new

      assert_raises UnknownComponentError do
        registry.fetch(:missing)
      end
    end

    test "exports component schema" do
      registry = ComponentRegistry.new
      registry.register(:hero, HeroComponent, description: "Large hero", props: { "title" => "string" })

      assert_equal [
        {
          "name" => "hero",
          "description" => "Large hero",
          "props" => {
            "title" => {
              "type" => "short_text",
              "label" => "Title",
              "description" => "string",
              "required" => true
            }
          }
        }
      ], registry.schema
    end

    test "normalizes typed component props" do
      registry = ComponentRegistry.new
      registry.register(:hero, HeroComponent, props: {
        title: "Headline",
        body: { type: :long_text, label: "Body copy", description: "Support copy", required: false }
      })

      props = registry.registered(:hero).normalized_props

      assert_equal :short_text, props[:title][:type]
      assert_equal "Headline", props[:title][:description]
      assert_equal "Body copy", props[:body][:label]
      assert_equal :long_text, props[:body][:type]
      assert_equal false, props[:body][:required]
    end

    test "filters components by site key" do
      site = Site.new(name: "Marketing", key: "marketing", host: "example.test", path_prefix: "/")
      registry = ComponentRegistry.new
      registry.register(:hero, HeroComponent, sites: %i[marketing])
      registry.register(:article_header, HeroComponent, sites: %i[blog])
      registry.register(:shared_cta, HeroComponent)

      assert_equal %i[hero shared_cta], registry.for_site(site).map(&:name)
    end

    test "normalizes collection item props" do
      registry = ComponentRegistry.new
      registry.register(:feature_grid, HeroComponent, props: {
        items: { type: :collection, min: 1, max: 4, item: { title: "Feature title" } }
      })

      collection = registry.registered(:feature_grid).normalized_props[:items]

      assert_equal :collection, collection[:type]
      assert_equal 1, collection[:min]
      assert_equal 4, collection[:max]
      assert_equal :short_text, collection[:item][:title][:type]
    end

    test "normalizes select options" do
      registry = ComponentRegistry.new
      registry.register(:feature_card, HeroComponent, props: {
        gradient: { type: :select, options: %w[sunset forest stone] }
      })

      select = registry.registered(:feature_card).normalized_props[:gradient]

      assert_equal :select, select[:type]
      assert_equal %w[sunset forest stone], select[:options]
    end
  end
end
