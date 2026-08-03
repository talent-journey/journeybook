module Journeybook
  class PageRenderer
    def initialize(
      parser: ComponentParser.new,
      markdown_renderer: MarkdownRenderer.new,
      component_renderer: ComponentRenderer.new,
      sanitizer: HtmlSanitizer.new
    )
      @parser = parser
      @markdown_renderer = markdown_renderer
      @component_renderer = component_renderer
      @sanitizer = sanitizer
    end

    # @param page_or_markdown [Journeybook::Page, String]
    # @return [String]
    def render(page_or_markdown, form_authenticity_token: nil, component_index: nil, component_anchors: false)
      @component_anchors = component_anchors
      markdown = page_or_markdown.respond_to?(:markdown) ? page_or_markdown.markdown : page_or_markdown
      extracted_markdown, components = @parser.extract(markdown)
        return render_component(components[component_index], form_authenticity_token, page_or_markdown) if component_index

        page = page_or_markdown if page_or_markdown.respond_to?(:markdown)
        html = @markdown_renderer.render(extracted_markdown)

      components.each_with_index do |component, index|
        html = html.gsub(%r{<p>\s*#{component.token}\s*</p>}, component.token)
          html = html.gsub(component.token, "#{component_anchor(index)}#{@component_renderer.render(component, page:)}")
      end

      @sanitizer.sanitize(inject_form_token(html, form_authenticity_token))
    end

    private

      def render_component(component, form_authenticity_token, page)
      return "" unless component

        @sanitizer.sanitize(inject_form_token(@component_renderer.render(component, page:), form_authenticity_token))
    end

    def component_anchor(index)
      return "" unless @component_anchors

      %(<span id="journeybook-preview-component-#{index}" data-journeybook-preview-component="#{index}"></span>)
    end

    def inject_form_token(html, token)
      return html if token.blank?

      action = Regexp.escape(Journeybook.configuration.form_action.to_s)
      form = %r{(<form\b(?=[^>]*\baction=(["'])#{action}\2)[^>]*>)}
      token_input = %(<input type="hidden" name="authenticity_token" value="#{ERB::Util.html_escape(token)}">)

      html.gsub(form) { "#{Regexp.last_match(1)}#{token_input}" }
    end
  end
end
