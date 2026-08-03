module Journeybook
  class NavigationMenu < ApplicationRecord
    belongs_to :site
    has_many :items, class_name: "NavigationItem", dependent: :destroy

    before_validation :normalize_key

    validates :key, :title, presence: true
    validates :key, uniqueness: { scope: :site_id }

    scope :ordered, -> { order(:position, :title) }

    def visible_items
      @visible_items ||= items.includes(:page).order(:position, :id).select(&:displayable?)
    end

    private

    def normalize_key
      self.key = key.to_s.parameterize(separator: "_").underscore
    end
  end
end
