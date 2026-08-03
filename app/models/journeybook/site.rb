module Journeybook
  class Site < ApplicationRecord
    has_many :pages, dependent: :destroy
    has_many :navigation_menus, dependent: :destroy

    before_validation :normalize_context_fields

    validates :name, :key, :host, :path_prefix, presence: true
    validates :key, uniqueness: true
    validates :path_prefix, uniqueness: { scope: :host }
    validates :default_locale, presence: true

    scope :for_host, ->(host) { where(host: host) }
    scope :by_longest_prefix, -> { order(Arel.sql("LENGTH(path_prefix) DESC")) }

    def layout_name
      layout.presence || Journeybook.configuration.default_layout
    end

    def relative_path_for(request_path)
      path = normalize_path(request_path)
      prefix = normalize_path(path_prefix)

      return path if prefix == "/"
      return unless path == prefix || path.start_with?("#{prefix}/")

      relative = path.delete_prefix(prefix)
      relative.presence || "/"
    end

    def matches_path?(request_path)
      relative_path_for(request_path).present?
    end

    def public_path_for(page)
      return unless page

      prefix = normalize_path(path_prefix)
      path = normalize_path(page.path)
      return path if prefix == "/"
      return prefix if path == "/"

      "#{prefix}#{path}"
    end

    private

    def normalize_context_fields
      self.key = key.presence || name.to_s.parameterize(separator: "_")
      self.key = key.to_s.strip.underscore
      self.path_prefix = normalize_path(path_prefix.presence || "/")
    end

    def normalize_path(value)
      path = value.to_s.strip
      path = "/#{path}" unless path.start_with?("/")
      path = path.squeeze("/")
      path = path.delete_suffix("/") unless path == "/"
      path.presence || "/"
    end
  end
end
