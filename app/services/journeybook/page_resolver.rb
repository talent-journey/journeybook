module Journeybook
  class PageResolver
    def self.from_request(request, path: nil, locale: nil)
      new(host: request.host, path: path, locale: locale)
    end

    def initialize(host:, path:, locale: nil)
      @host = host
      @path = path
      @locale = locale
    end

    def call
      matched_site = site
      return unless matched_site

      pages = matched_site.pages.published.by_path(matched_site.relative_path_for(normalized_path))
      pages = pages.where(locale: @locale) if @locale.present?
      pages.first
    end

    def site
      @site ||= find_site
    end

    private

    def find_site
      sites = matching_host_sites.presence || local_sites
      sites.by_longest_prefix.detect { |site| site.matches_path?(normalized_path) }
    end

    def matching_host_sites
      Site.for_host(@host)
    end

    def local_sites
      return Site.none unless local_host?

      Site.where(host: %w[localhost 127.0.0.1])
    end

    def local_host?
      @host.in?(%w[localhost 127.0.0.1 0.0.0.0])
    end

    def normalized_path
      path = @path.to_s.strip
      path = "/#{path}" unless path.start_with?("/")
      path = path.squeeze("/")
      path = path.delete_suffix("/") unless path == "/"
      path.presence || "/"
    end
  end
end
