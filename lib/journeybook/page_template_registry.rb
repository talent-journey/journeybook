module Journeybook
  class PageTemplateRegistry
    Template = Data.define(:key, :metadata) do
      def name
        metadata.fetch(:name, key.to_s.humanize)
      end

      def description
        metadata.fetch(:description, "")
      end

      def page_type
        metadata.fetch(:page_type, "page").to_s
      end

      def markdown
        metadata.fetch(:markdown, "").to_s
      end

      def path_prefix
        metadata[:path_prefix].to_s.presence
      end

      def path_hint
        metadata[:path_hint].to_s.presence
      end

      def available_for_site?(site)
        sites = Array(metadata[:sites]).map(&:to_s)
        sites.empty? || site && site.key.in?(sites)
      end
    end

    include Enumerable

    def initialize
      @templates = {}
    end

    def register(key, **metadata)
      normalized_key = normalize_key(key)
      @templates[normalized_key] = Template.new(normalized_key, metadata)
    end

    def fetch(key)
      @templates.fetch(normalize_key(key))
    end

    def registered(key)
      @templates[normalize_key(key)]
    end

    def for_site(site)
      @templates.values.select { |template| template.available_for_site?(site) }
    end

    def each(&)
      @templates.values.each(&)
    end

    private

    def normalize_key(key)
      key.to_s.parameterize(separator: "_").underscore.to_sym
    end
  end
end
