module Journeybook
  class NavigationItem < ApplicationRecord
    belongs_to :navigation_menu
    belongs_to :page, class_name: "Page", optional: true

    before_validation :normalize_external_url

    validates :label, presence: true
    validates :external_url, format: { with: %r{\A(?:https?://|/|#)}, message: "must be an absolute URL, path, or anchor" }, allow_blank: true
    validate :has_destination
    validate :page_belongs_to_menu_site

    scope :ordered, -> { order(:position, :id) }

    def displayable?
      visible? && (external_url.present? || page&.published?)
    end

    def href
      navigation_menu.site.public_path_for(page) || external_url
    end

    def target
      "_blank" if open_in_new_window?
    end

    private

    def normalize_external_url
      self.external_url = external_url.to_s.strip.presence
    end

    def has_destination
      return if page.present? ^ external_url.present?

      errors.add(:base, "Select either a page or an external URL")
    end

    def page_belongs_to_menu_site
      return unless page && page.site_id != navigation_menu.site_id

      errors.add(:page, "must belong to the same site as the menu")
    end
  end
end
