require "test_helper"

module Journeybook
  class PageRendererTest < ActiveSupport::TestCase
    class TestHeroComponent
      def self.render(title:)
        %(<section class="hero"><h2>#{title}</h2></section>)
      end
    end

    test "renders markdown and registered components" do
      registry = ComponentRegistry.new
      registry.register(:hero, TestHeroComponent)

      renderer = PageRenderer.new(component_renderer: ComponentRenderer.new(registry: registry))
      html = renderer.render("# Hello\n\n{{ hero title=\"Journeybook\" }}")

      assert_includes html, "Hello</h1>"
      assert_includes html, "<section class=\"hero\"><h2>Journeybook</h2></section>"
    end

    test "does not render hidden components" do
      registry = ComponentRegistry.new
      registry.register(:hero, TestHeroComponent)

      renderer = PageRenderer.new(component_renderer: ComponentRenderer.new(registry: registry))
      html = renderer.render('{{ hero title="Hidden" journeybook_hidden="true" }}')

      refute_includes html, "Hidden"
    end

    test "adds a CSRF token to Journeybook forms" do
      html = PageRenderer.new.render('<form action="/journeybook/form" method="post"></form>', form_authenticity_token: "token")

      assert_includes html, 'name="authenticity_token" value="token"'
    end

    test "passes collection props as arrays to components" do
      component = Class.new do
        def self.render(items:)
          items.map { |item| item[:title] }.join(", ")
        end
      end
      registry = ComponentRegistry.new
      registry.register(:feature_grid, component, props: {
        items: { type: :collection, min: 1, item: { title: "Feature title" } }
      })
      renderer = PageRenderer.new(component_renderer: ComponentRenderer.new(registry: registry))

      html = renderer.render(%({{ feature_grid items='[{"title":"One"},{"title":"Two"}]' }}))

      assert_includes html, "One, Two"
    end

    test "passes the current page to data-driven components that accept it" do
      site = Site.create!(name: "Data", host: "data.test", default_locale: "en")
      page = Page.create!(site: site, title: "Index", slug: "index", path: "/", markdown: "{{ post_list }}", status: "draft", locale: "en")
      component = Class.new do
        def self.render(page:)
          "<section>#{page.site.key}-list</section>"
        end
      end
      registry = ComponentRegistry.new
      registry.register(:post_list, component)
      renderer = PageRenderer.new(component_renderer: ComponentRenderer.new(registry: registry))

      html = renderer.render(page)

      assert_includes html, "<section>data-list</section>"
    end

    test "does not pass the page to components that do not accept it" do
      component = Class.new do
        def self.render(title:)
          "<section>#{title}</section>"
        end
      end
      registry = ComponentRegistry.new
      registry.register(:hero, component, props: { title: "Headline" })
      renderer = PageRenderer.new(component_renderer: ComponentRenderer.new(registry: registry))

      html = renderer.render("{{ hero title=\"Journeybook\" }}")

      assert_includes html, "<section>Journeybook</section>"
    end

    test "renders only the selected component in focus mode" do
      cta_component = Class.new do
        def self.render(title:)
          "<section>CTA: #{title}</section>"
        end
      end
      registry = ComponentRegistry.new
      registry.register(:hero, TestHeroComponent, props: { title: "Headline" })
      registry.register(:cta, cta_component, props: { title: "CTA headline" })
      renderer = PageRenderer.new(component_renderer: ComponentRenderer.new(registry: registry))

      html = renderer.render("{{ hero title=\"First\" }}\n\n{{ cta title=\"Second\" }}", component_index: 1)

      assert_includes html, "CTA: Second"
      refute_includes html, "First"
    end

    test "adds component anchors only when requested" do
      registry = ComponentRegistry.new
      registry.register(:hero, TestHeroComponent, props: { title: "Headline" })
      renderer = PageRenderer.new(component_renderer: ComponentRenderer.new(registry: registry))

      overview = renderer.render('{{ hero title="First" }}', component_anchors: true)
      focus = renderer.render('{{ hero title="First" }}', component_index: 0)

      assert_includes overview, 'id="journeybook-preview-component-0"'
      refute_includes focus, "journeybook-preview-component"
    end

    test "renders more than ten components without overlapping placeholder tokens" do
      registry = ComponentRegistry.new
      registry.register(:hero, TestHeroComponent, props: { title: "Headline" })
      renderer = PageRenderer.new(component_renderer: ComponentRenderer.new(registry: registry))
      markdown = (0..10).map { |index| %({{ hero title="Component #{index}" }}) }.join("\n\n")

      html = renderer.render(markdown)

      assert_equal 1, html.scan("Component 1</h2>").length
      assert_equal 1, html.scan("Component 10</h2>").length
    end

    test "removes scripts and inline event handlers" do
      html = HtmlSanitizer.new.sanitize('<p onclick="alert(1)">Hi</p><script>alert(1)</script>')

      assert_includes html, "<p>Hi</p>"
      refute_includes html, "onclick"
      refute_includes html, "script"
    end

    test "allows safe form controls for contact form components" do
      html = HtmlSanitizer.new.sanitize(<<~HTML)
        <form action="/journeybook/form" method="post">
          <label>Name<input name="name" type="text" required autocomplete="name"></label>
          <textarea name="message" rows="6" placeholder="Message"></textarea>
          <button type="submit">Send</button>
        </form>
      HTML

      assert_includes html, '<form action="/journeybook/form" method="post">'
      assert_includes html, '<input name="name" type="text" required="" autocomplete="name">'
      assert_includes html, '<textarea name="message" rows="6" placeholder="Message">'
      assert_includes html, '<button type="submit">Send</button>'
    end

    test "allows trusted video iframe embeds" do
      html = HtmlSanitizer.new.sanitize(<<~HTML)
        <iframe src="https://www.youtube.com/embed/abc123" title="Demo" class="video" loading="lazy" allow="fullscreen" allowfullscreen></iframe>
      HTML

      assert_includes html, '<iframe src="https://www.youtube.com/embed/abc123"'
      assert_includes html, 'allowfullscreen=""'
    end

    test "removes untrusted iframe embeds" do
      html = HtmlSanitizer.new.sanitize(<<~HTML)
        <iframe src="https://evil.example/embed/abc123" title="Demo"></iframe>
      HTML

      refute_includes html, "iframe"
      refute_includes html, "evil.example"
    end
  end
end
