module Journeybook
  class HtmlSanitizer
    ALLOWED_TAGS = %w[
      a abbr article blockquote br button code dd div dl dt em figcaption figure form h1 h2 h3 h4 h5 h6 i
      hr iframe img input kbd label li ol p pre span strong table tbody td textarea th thead tr ul
      section
    ].freeze

    ALLOWED_ATTRIBUTES = %w[
      action allow allowfullscreen alt autocomplete class height href id loading method name placeholder referrerpolicy rel required rows src target title type value width
    ].freeze

    ALLOWED_IFRAME_HOSTS = %w[
      www.youtube.com youtube.com www.youtube-nocookie.com youtube-nocookie.com player.vimeo.com
    ].freeze

    # @param html [String]
    # @return [String]
    def sanitize(html)
      remove_unsafe_iframes(sanitizer.sanitize(html.to_s, tags: ALLOWED_TAGS, attributes: ALLOWED_ATTRIBUTES).to_s)
    end

    private

    def remove_unsafe_iframes(html)
      fragment = Nokogiri::HTML5.fragment(html)

      fragment.css("iframe").each do |iframe|
        iframe.remove unless safe_iframe_src?(iframe["src"])
      end

      fragment.to_html
    end

    def safe_iframe_src?(src)
      uri = URI.parse(src.to_s)
      uri.is_a?(URI::HTTPS) && ALLOWED_IFRAME_HOSTS.include?(uri.host.to_s.downcase)
    rescue URI::InvalidURIError
      false
    end

    def sanitizer
      @sanitizer ||= Rails::HTML5::SafeListSanitizer.new
    end
  end
end
