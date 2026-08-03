require "test_helper"

class AdminTest < ActionDispatch::IntegrationTest
  setup do
    @site = Journeybook::Site.create!(name: "Main", host: "example.test", default_locale: "en")
    @page = @site.pages.create!(
      title: "Home",
      slug: "home",
      path: "/",
      markdown: "# Home",
      status: "draft",
      locale: "en"
    )
  end

  test "renders admin dashboard" do
    get "/journeybook"

    assert_response :success
    assert_includes response.body, "Journeybook"
    assert_includes response.body, "New page"
    assert_includes response.body, 'class="is-active" aria-current="page" href="/journeybook/">Dashboard'
  end

  test "highlights active admin section" do
    get "/journeybook/pages"

    assert_response :success
    assert_includes response.body, 'class="is-active" aria-current="page" href="/journeybook/pages">Pages'
    assert_includes response.body, 'data-source-label="Edit source"'
    assert_includes response.body, "data-source-edit"
  end

  test "manages style prompts and selects one in the AI builder" do
    post "/journeybook/ai/styles", params: { ai_style_prompt: { name: "Feature page", prompt: "Use concise feature sections." } }

    style_prompt = Journeybook::AiStylePrompt.last
    assert_redirected_to "/journeybook/ai/styles"

    get "/journeybook/ai/new"

    assert_response :success
    assert_includes response.body, "Generate an AI-powered page"
    assert_includes response.body, "Manage style prompts"
    assert_includes response.body, style_prompt.name
    refute_includes response.body, Journeybook.configuration.openai_model
  end

  test "passes the selected style prompt to page generation" do
    style_prompt = Journeybook::AiStylePrompt.create!(name: "Article", prompt: "Use an editorial structure.")
    calls = []
    generator = Object.new
    generator.define_singleton_method(:generate) { |prompt:| "{{ hero title=\"Generated\" }}" }
    original_new = Journeybook::Ai::MarkdownGenerator.method(:new)
    Journeybook::Ai::MarkdownGenerator.define_singleton_method(:new) do |site:, style_prompt:, template:|
      calls << { site:, style_prompt:, template: }
      generator
    end

    post "/journeybook/ai", params: {
      prompt: "Create an article",
      ai_style_prompt_id: style_prompt.id,
      page: { site_id: @site.id, title: "Article", path: "/article", locale: "en" }
    }

    assert_response :success
    assert_equal [ { site: @site, style_prompt: "Use an editorial structure.", template: nil } ], calls
    assert_includes response.body, "Generated"
  ensure
    Journeybook::Ai::MarkdownGenerator.define_singleton_method(:new, original_new)
  end

  test "generates a template-constrained blog draft" do
    template = Journeybook.register_template :blog_post,
      name: "Blog post",
      description: "Article header and longform content.",
      page_type: "blog_post",
      path_prefix: "/blog",
      path_hint: "/blog/your-post-title",
      markdown: "{{ article_hero }}\n\n{{ text text=\"Start writing your article here.\" }}"
    calls = []
    generator = Object.new
    generator.define_singleton_method(:generate) { |prompt:| "{{ article_hero }}\n\n{{ text text=\"Generated article\" }}" }
    original_new = Journeybook::Ai::MarkdownGenerator.method(:new)
    Journeybook::Ai::MarkdownGenerator.define_singleton_method(:new) do |site:, style_prompt:, template:|
      calls << { site:, style_prompt:, template: }
      generator
    end

    post "/journeybook/ai", params: {
      prompt: "Write about onboarding",
      template_key: "blog_post",
      page: { site_id: @site.id, title: "Onboarding", path: "", locale: "en" }
    }

    assert_response :success
    assert_equal [ { site: @site, style_prompt: nil, template: template } ], calls
    assert_includes response.body, "Blog post"
    assert_includes response.body, "Generated article"
    assert_includes response.body, 'selected="selected" value="blog_post"'
    assert_includes response.body, 'name="template_key"'
  ensure
    Journeybook::Ai::MarkdownGenerator.define_singleton_method(:new, original_new)
  end

  test "creates a manual page without visible source or component reference fields" do
    get "/journeybook/pages/new"

    assert_response :success
    refute_includes response.body, '<textarea name="page[markdown]"'
    refute_includes response.body, "Component reference"
    assert_includes response.body, 'value="{{ hero }}"'
    refute_includes response.body, "# New page"
    refute_includes response.body, "Start writing Markdown here"
  end

  test "starts a blog post from a registered template" do
    Journeybook.register_template :blog_post,
      name: "Blog post",
      description: "Article header and longform content.",
      page_type: "blog_post",
      path_prefix: "/blog",
      path_hint: "/blog/your-post-title",
      markdown: "{{ article_hero }}\n\n{{ text text=\"Start writing your article here.\" }}"

    get "/journeybook/pages/new", params: { site_id: @site.id, template: "blog_post" }

    assert_response :success
    assert_includes response.body, "Starting with the <strong>Blog post</strong> template"
    assert_includes response.body, 'name="page[page_type]"'
    assert_includes response.body, 'selected="selected" value="blog_post"'
    assert_includes response.body, 'name="page[markdown]"'
    assert_includes response.body, "article_hero"

    assert_difference -> { Journeybook::Page.count } do
      post "/journeybook/pages", params: {
        template_key: "blog_post",
        page: {
          site_id: @site.id,
          title: "Hiring trends",
          path: "",
          markdown: "{{ article_hero }}\n\n{{ text text=\"Start writing your article here.\" }}",
          page_type: "blog_post",
          status: "draft",
          locale: "en"
        }
      }
    end

    page = Journeybook::Page.order(:id).last
    assert_equal "/blog/hiring-trends", page.path
    assert_equal "blog_post", page.page_type
  end

  test "edits a page's complete markdown source" do
    get "/journeybook/pages/#{@page.id}/source", params: { site_id: @site.id }

    assert_response :success
    assert_includes response.body, "Edit the complete Markdown source for this page."
    assert_includes response.body, 'class="jb-form jb-source-editor"'
    assert_includes response.body, "# Home"

    patch "/journeybook/pages/#{@page.id}/source", params: { site_id: @site.id, page: { markdown: "# Updated source" } }

    assert_redirected_to "/journeybook/pages/#{@page.id}/source?site_id=#{@site.id}"
    assert_equal "# Updated source", @page.reload.markdown
  end

  test "highlights active library section" do
    get "/journeybook/library"

    assert_response :success
    assert_includes response.body, 'class="is-active" aria-current="page" href="/journeybook/library">Library'
  end

  test "edits navigation items with link type controls" do
    menu = @site.navigation_menus.create!(key: "footer_product", title: "Product")
    item = menu.items.create!(label: "About", page: @page)

    get "/journeybook/navigation/#{menu.id}/navigation_items/#{item.id}/edit", params: { site_id: @site.id }

    assert_response :success
    assert_includes response.body, "Link type"
    assert_includes response.body, "Journeybook page"
    assert_includes response.body, 'type="checkbox"'
    refute_includes response.body, 'name="navigation_item[position]"'

    patch "/journeybook/navigation/#{menu.id}/navigation_items/#{item.id}", params: {
      navigation_item: { label: "External", page_id: "", external_url: "https://example.test", visible: "1", open_in_new_window: "1" }
    }

    assert_redirected_to "/journeybook/navigation/#{menu.id}/edit"
    assert_equal "https://example.test", item.reload.external_url
    assert item.open_in_new_window?
  end

  test "uploads and deletes image library asset" do
    deleted = []
    fake_client = Class.new do
      define_method(:initialize) { |deleted_keys| @deleted_keys = deleted_keys }
      define_method(:upload) do |_file|
        Journeybook::Storage::S3Client::Upload.new(
          storage_key: "journeybook/media/test.svg",
          original_filename: "test.svg",
          content_type: "image/svg+xml",
          byte_size: 114,
          checksum: "checksum"
        )
      end
      define_method(:delete) { |storage_key| @deleted_keys << storage_key }
    end.new(deleted)
    original_new = Journeybook::Storage::S3Client.method(:new)
    Journeybook::Storage::S3Client.define_singleton_method(:new) { fake_client }

    assert_difference -> { Journeybook::MediaAsset.count } do
      post "/journeybook/library", params: {
        media_asset: {
          file: Rack::Test::UploadedFile.new(file_fixture("test.svg"), "image/svg+xml"),
          title: "Test image",
          alt_text: "A test image",
          tags: "test"
        }
      }
    end

    asset = Journeybook::MediaAsset.last
    assert_redirected_to "/journeybook/library"
    assert_equal "journeybook/media/test.svg", asset.storage_key

    assert_difference -> { Journeybook::MediaAsset.count }, -1 do
      delete "/journeybook/library/#{asset.id}"
    end

    assert_equal [ "journeybook/media/test.svg" ], deleted
  ensure
    Journeybook::Storage::S3Client.define_singleton_method(:new, original_new)
  end

  test "creates a page from admin" do
    assert_difference -> { Journeybook::Page.count } do
      post "/journeybook/pages", params: {
        page: {
          site_id: @site.id,
          title: "About",
          path: "/about",
          markdown: "# About",
          status: "draft",
          locale: "en"
        }
      }
    end

    assert_redirected_to %r{/journeybook/pages/\d+/edit}
  end

  test "duplicates a page as a draft with a unique path" do
    @page.update!(markdown: "# Original", status: "published", published_at: Time.current)

    assert_difference -> { Journeybook::Page.count } do
      post "/journeybook/pages/#{@page.id}/duplicate", params: { site_id: @site.id }
    end

    duplicate = Journeybook::Page.order(:id).last
    assert_redirected_to "/journeybook/pages/#{duplicate.id}/edit?site_id=#{@site.id}"
    assert_equal "Copy of Home", duplicate.title
    assert_equal "/home-copy", duplicate.path
    assert_equal "draft", duplicate.status
    assert_nil duplicate.published_at
    assert_equal @page.markdown, duplicate.markdown
  end

  test "renders page editor with layout sidebar and preview" do
    Journeybook.components.register(:test_card, String, description: "A test card", props: { title: "Headline" })
    other_page = @site.pages.create!(title: "About", path: "/about", markdown: "{{ test_card title=\"About\" }}", status: "draft", locale: "en")
    @page.update!(markdown: '{{ test_card title="Card title" }}')

    get "/journeybook/pages/#{@page.id}/edit", params: { tab: "layout", component: 0 }

    assert_response :success
    assert_includes response.body, @page.title
    refute_includes response.body, "/journeybook/pages/#{other_page.id}/edit"
    assert_includes response.body, "Desktop"
    assert_includes response.body, "Mobile"
    assert_includes response.body, "Publish"
    assert_includes response.body, "/journeybook/pages/#{@page.id}/publish"
    assert_includes response.body, "data-edit-page-shortcut"
    assert_includes response.body, "/journeybook/pages/#{@page.id}/source"
    assert_includes response.body, "hidden=\"hidden\""
    assert_includes response.body, "test_card #1"
    assert_includes response.body, "Back to page"
    refute_includes response.body, 'aria-label="Editor sections"'
    refute_includes response.body, "jb-page-switcher"
    assert_includes response.body, "Card title"
    refute_includes response.body, "A test card"
    assert_includes response.body, "/journeybook/pages/#{@page.id}/preview"
    refute_includes response.body, "/journeybook/pages/#{@page.id}/component/new"
    refute_includes response.body, "Add component"
    assert_includes response.body, "data-live-preview-form"
    assert_includes response.body, "jb-editor-preview-frame"
    assert_includes response.body, "jb-component-editor-actions"
  end

  test "shows an unpublish action for published pages in the editor" do
    @page.update!(status: "published", published_at: Time.current)

    get "/journeybook/pages/#{@page.id}/edit", params: { tab: "layout" }

    assert_response :success
    assert_includes response.body, "Unpublish"
    assert_includes response.body, "/journeybook/pages/#{@page.id}/draft"
    refute_includes response.body, ">Publish<"
  end

  test "previews only the selected component" do
    component_class = Class.new do
      def self.render(title:)
        "<section>#{title}</section>"
      end
    end
    Journeybook.components.register(:first_card, component_class, props: { title: "Headline" })
    Journeybook.components.register(:second_card, component_class, props: { title: "Headline" })
    @page.update!(markdown: '{{ first_card title="First" }} {{ second_card title="Second" }}')

    get "/journeybook/pages/#{@page.id}/preview", params: { component: 1, site_id: @site.id }

    assert_response :success
    assert_includes response.body, "Second"
    refute_includes response.body, "First"
    refute_includes response.body, 'id="journeybook-preview-component-'
    assert_includes response.body, 'style="padding-top: 6rem"'
  end

  test "adds component anchors to the full page preview" do
    component_class = Class.new do
      def self.render(title:)
        "<section>#{title}</section>"
      end
    end
    Journeybook.components.register(:preview_card, component_class, props: { title: "Headline" })
    @page.update!(markdown: '{{ preview_card title="First" }} {{ preview_card title="Second" }}')

    get "/journeybook/pages/#{@page.id}/preview", params: { site_id: @site.id }

    assert_response :success
    assert_includes response.body, 'id="journeybook-preview-component-0"'
    assert_includes response.body, 'id="journeybook-preview-component-1"'
    assert_includes response.body, "journeybook:scroll-preview"
    refute_includes response.body, 'style="padding-top: 6rem"'
  end

  test "renders component drag sorting and delete controls" do
    @page.update!(markdown: "{{ hero title=\"First\" }}\n\n{{ cta_panel title=\"Second\" }}")

    get "/journeybook/pages/#{@page.id}/edit", params: { tab: "layout" }

    assert_response :success
    assert_includes response.body, "Edit"
    assert_includes response.body, "Delete"
    refute_includes response.body, "jb-component-instance-link"
    assert_includes response.body, "data-sortable-list"
    assert_includes response.body, "data-sortable-handle"
    assert_includes response.body, "/journeybook/pages/#{@page.id}/components/reorder"
  end

  test "moves a component from the editor" do
    @page.update!(markdown: "{{ hero title=\"First\" }}\n\n{{ cta_panel title=\"Second\" }}")

    patch "/journeybook/pages/#{@page.id}/component/move", params: {
      site_id: @site.id,
      component_index: 0,
      direction: "down"
    }

    assert_redirected_to %r{/journeybook/pages/#{@page.id}/edit}
    assert_includes response.location, "tab=layout"
    assert_equal "{{ cta_panel title=\"Second\" }}\n\n{{ hero title=\"First\" }}", @page.reload.markdown
  end

  test "reorders components from the editor" do
    @page.update!(markdown: "{{ hero title=\"First\" }}\n\n{{ cta_panel title=\"Second\" }}")

    patch "/journeybook/pages/#{@page.id}/components/reorder", params: {
      site_id: @site.id,
      component_indexes: [ 1, 0 ]
    }

    assert_response :no_content
    assert_equal "{{ cta_panel title=\"Second\" }}\n\n{{ hero title=\"First\" }}", @page.reload.markdown
  end

  test "reorders navigation items" do
    menu = @site.navigation_menus.create!(key: "footer_product", title: "Product")
    first = menu.items.create!(label: "First", external_url: "/first", position: 0)
    second = menu.items.create!(label: "Second", external_url: "/second", position: 1)

    patch "/journeybook/navigation/#{menu.id}/navigation_items/reorder", params: { item_ids: [ second.id, first.id ] }

    assert_response :no_content
    assert_equal [ second, first ], menu.items.ordered.to_a
  end

  test "manages redirects" do
    post "/journeybook/redirects", params: { redirect: { from: "/old", to: "/new", status_code: 301 } }

    assert_redirected_to "/journeybook/redirects"
    assert_equal "/new", Journeybook::Redirect.find_by!(from: "/old").to
  end

  test "does not publish pages with invalid components" do
    @page.update!(markdown: '{{ missing_component title="Broken" }}')

    patch "/journeybook/pages/#{@page.id}/publish", params: { site_id: @site.id }

    assert_redirected_to %r{/journeybook/pages/#{@page.id}/edit}
    assert_equal "draft", @page.reload.status
    assert_includes flash[:alert], "missing_component"
  end

  test "shows publishing errors from the editor" do
    @page.update!(markdown: '{{ missing_component title="Broken" }}')

    get "/journeybook/pages/#{@page.id}/edit", params: { site_id: @site.id, tab: "layout" }

    assert_response :success
    assert_includes response.body, "Errors"
    assert_includes response.body, "/journeybook/pages/#{@page.id}/errors"

    get "/journeybook/pages/#{@page.id}/errors", params: { site_id: @site.id }

    assert_response :success
    assert_includes response.body, "Publishing errors"
    assert_includes response.body, "missing_component"
  end

  test "deletes a component from the editor" do
    @page.update!(markdown: "# Intro\n\n{{ hero title=\"First\" }}\n\n{{ cta_panel title=\"Second\" }}")

    delete "/journeybook/pages/#{@page.id}/component", params: {
      site_id: @site.id,
      component_index: 0
    }

    assert_redirected_to %r{/journeybook/pages/#{@page.id}/edit}
    assert_includes response.location, "tab=layout"
    assert_equal "# Intro\n\n{{ cta_panel title=\"Second\" }}", @page.reload.markdown
  end

  test "toggles a component visibility from the editor" do
    @page.update!(markdown: '{{ hero title="Hidden" }}')

    patch "/journeybook/pages/#{@page.id}/component/visibility", params: {
      site_id: @site.id,
      component_index: 0
    }

    assert_redirected_to %r{/journeybook/pages/#{@page.id}/edit}
    assert_includes @page.reload.markdown, 'journeybook_hidden="true"'
  end

  test "renders component picker for a page" do
    Journeybook.components.register(:addable_card, String, description: "Addable card", props: { title: "Headline" })

    get "/journeybook/pages/#{@page.id}/component/new", params: { component: "addable_card" }

    assert_response :success
    assert_includes response.body, "Add component"
    assert_includes response.body, "addable_card"
    assert_includes response.body, "Addable card"
    assert_includes response.body, "/journeybook/components/addable_card/preview"
  end

  test "adds a component to the bottom of a page" do
    Journeybook.components.register(:addable_card, String, props: { title: "Headline", body: { type: :long_text, label: "Body" } })

    post "/journeybook/pages/#{@page.id}/component", params: {
      site_id: @site.id,
      component_name: "addable_card"
    }

    assert_redirected_to %r{/journeybook/pages/#{@page.id}/edit}
    assert_includes response.location, "tab=layout"
    assert_includes response.location, "component=0"
    assert_equal "# Home\n\n{{ addable_card title=\"\" body=\"\" }}", @page.reload.markdown
  end

  test "does not add an unknown component" do
    assert_no_changes -> { @page.reload.markdown } do
      post "/journeybook/pages/#{@page.id}/component", params: {
        site_id: @site.id,
        component_name: "unknown_card"
      }
    end

    assert_redirected_to "/journeybook/pages/#{@page.id}/component/new?site_id=#{@site.id}"
  end

  test "renders image picker for image component props" do
    original_public_base_url = Journeybook.configuration.s3_public_base_url
    Journeybook.configuration.s3_public_base_url = "https://cdn.example.test"
    Journeybook.components.register(:image_card, String, props: {
      image_url: { type: :image, label: "Image", description: "Pick an image" },
      caption: { type: :long_text, description: "Caption copy" }
    })
    Journeybook::MediaAsset.create!(title: "Hero image", alt_text: "A hero", storage_key: "journeybook/media/hero.jpg", original_filename: "hero.jpg", content_type: "image/jpeg", byte_size: 12)
    @page.update!(markdown: '{{ image_card image_url="https://cdn.example.test/journeybook/media/hero.jpg" caption="Old" }}')

    get "/journeybook/pages/#{@page.id}/edit", params: { tab: "layout", component: 0 }

    assert_response :success
    assert_includes response.body, "jb-image-picker-modal"
    assert_includes response.body, "data-image-picker-open"
    assert_includes response.body, "data-image-picker-asset"
    assert_includes response.body, "Hero image"
    refute_includes response.body, "Pick an image"
    assert_includes response.body, "textarea"
  ensure
    Journeybook.configuration.s3_public_base_url = original_public_base_url
  end

  test "renders url component props without browser url validation" do
    Journeybook.components.register(:link_card, String, props: {
      href: { type: :url, description: "Relative path, anchor, or absolute URL" }
    })
    @page.update!(markdown: '{{ link_card href="/knowledge-base" }}')

    get "/journeybook/pages/#{@page.id}/edit", params: { tab: "layout", component: 0 }

    assert_response :success
    assert_includes response.body, "type=\"text\""
    assert_includes response.body, "Journeybook page"
    assert_includes response.body, "Current window"
    assert_not_includes response.body, "type=\"url\""
  end

  test "renders video component props without browser url validation" do
    Journeybook.components.register(:video_card, String, props: {
      video_url: { type: :video, description: "YouTube, Vimeo, or direct video URL" }
    })
    @page.update!(markdown: '{{ video_card video_url="https://www.youtube.com/watch?v=abc123" }}')

    get "/journeybook/pages/#{@page.id}/edit", params: { tab: "layout", component: 0 }

    assert_response :success
    assert_includes response.body, "type=\"text\""
    assert_includes response.body, "https://www.youtube.com/watch?v=..."
    assert_not_includes response.body, "type=\"url\""
  end

  test "updates a page component from the editor" do
    Journeybook.components.register(:editable_card, String, props: { title: "Headline", body: "Body copy" })
    @page.update!(markdown: '{{ editable_card title="Old" body="Keep" custom="Preserve" }}')

    patch "/journeybook/pages/#{@page.id}/component", params: {
      site_id: @site.id,
      component_index: 0,
      component_props: {
        title: "New",
        body: "Updated body"
      }
    }

    assert_redirected_to %r{/journeybook/pages/#{@page.id}/edit}
    assert_includes response.location, "tab=layout"
    assert_includes response.location, "component=0"
    assert_equal '{{ editable_card title="New" body="Updated body" custom="Preserve" }}', @page.reload.markdown
  end

  test "saves a page component and returns to the component list" do
    Journeybook.components.register(:editable_card, String, props: { title: "Headline" })
    @page.update!(markdown: '{{ editable_card title="Old" }}')

    patch "/journeybook/pages/#{@page.id}/component", params: {
      site_id: @site.id,
      component_index: 0,
      save_and_back: "true",
      component_props: { title: "New" }
    }

    assert_redirected_to %r{/journeybook/pages/#{@page.id}/edit}
    assert_includes response.location, "tab=layout"
    assert_not_includes response.location, "component="
  end

  test "renders collection props as an editable repeater" do
    Journeybook.components.register(:feature_grid, String, props: {
      items: { type: :collection, min: 1, max: 4, item: { title: "Feature title", image: { type: :image, required: false }, gradient: { type: :select, options: %w[sunset forest] } } }
    })
    @page.update!(markdown: %({{ feature_grid items='[{"title":"One","image":"https://cdn.example.test/image.jpg","gradient":"sunset"}]' }}))

    get "/journeybook/pages/#{@page.id}/edit", params: { tab: "layout", component: 0 }

    assert_response :success
    assert_includes response.body, "data-collection"
    assert_includes response.body, "Add item"
    assert_includes response.body, "Feature title"
    assert_includes response.body, '<option selected="selected" value="sunset">sunset</option>'
    assert_includes response.body, "jb-collection-remove"
    assert_includes response.body, 'aria-label="Remove items 1"'
    assert_includes response.body, "jb-image-picker-trigger"
  end

  test "previews a page" do
    get "/journeybook/pages/#{@page.id}/preview"

    assert_response :success
    assert_includes response.body, "Home"
    assert_includes response.body, "journeybook-page"
    assert_not_includes response.body, "jb-shell"
  end

  test "renders component reference" do
    registry = Journeybook.components
    registry.register(:test_card, String, description: "A test card", props: { title: "Headline" })

    get "/journeybook/components"

    assert_response :success
    assert_includes response.body, "test_card"
    assert_includes response.body, "A test card"
  end

  test "renders selected component preview" do
    component_class = Class.new do
      def self.preview_props
        { title: "A host-defined preview" }
      end

      def self.render(title:)
        %(<section class="test-preview">#{title}</section>)
      end
    end
    Journeybook.components.register(:test_preview_card, component_class, description: "Previewable card", props: { title: "Headline" })

    get "/journeybook/components", params: { component: "test_preview_card" }

    assert_response :success
    assert_includes response.body, "Previewable card"
    assert_includes response.body, "/journeybook/components/test_preview_card/preview"

    get "/journeybook/components/test_preview_card/preview"

    assert_response :success
    assert_includes response.body, "test-preview"
    assert_includes response.body, "A host-defined preview"
    assert_not_includes response.body, "jb-shell"
  end

  test "renders host-defined collection props for component previews" do
    component_class = Class.new do
      def self.preview_props
        {
          items: [
            { question: "Host question one", answer: "Host answer one" },
            { question: "Host question two", answer: "Host answer two" },
            { question: "Host question three", answer: "Host answer three" }
          ]
        }
      end

      def self.render(items:)
        items.map { |item| "<section>#{item[:question]}: #{item[:answer]}</section>" }.join
      end
    end
    Journeybook.components.register(
      :preview_accordion,
      component_class,
      props: {
        items: {
          type: :collection,
          item: {
            question: { description: "Question", required: false },
            answer: { type: :long_text, description: "Answer", required: false }
          }
        }
      }
    )

    get "/journeybook/components/preview_accordion/preview"

    assert_response :success
    assert_includes response.body, "Host question one"
    assert_includes response.body, "Host question two"
    assert_includes response.body, "Host question three"
  end
end
