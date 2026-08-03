module Journeybook
  class Page < ApplicationRecord
    STATUSES = %w[draft published archived].freeze
    PAGE_TYPES = %w[page blog_post kb_article glossary_term].freeze

    belongs_to :site
    belongs_to :parent, class_name: "Page", optional: true
    has_many :children, class_name: "Page", foreign_key: :parent_id, inverse_of: :parent, dependent: :nullify
    has_many :navigation_items, class_name: "NavigationItem", dependent: :nullify

    before_validation :generate_slug
    before_validation :normalize_path

    validates :title, :slug, :path, :markdown, :status, :locale, :page_type, presence: true
    validates :status, inclusion: { in: STATUSES }
    validates :page_type, inclusion: { in: PAGE_TYPES }
    validates :slug, uniqueness: { scope: %i[site_id locale] }
    validates :path, uniqueness: { scope: %i[site_id locale] }
    validate :parent_is_valid_knowledge_base_article
    validate :published_components_are_valid

    scope :published, -> { where(status: "published").where("published_at IS NULL OR published_at <= ?", Time.current) }
    scope :draft, -> { where(status: "draft") }
    scope :by_slug, ->(slug) { where(slug: slug) }
    scope :by_path, ->(path) { where(path: path) }
    scope :by_page_type, ->(type) { where(page_type: type) }
    scope :blog_posts, -> { by_page_type("blog_post") }
    scope :kb_articles, -> { by_page_type("kb_article") }
    scope :glossary_terms, -> { by_page_type("glossary_term") }
    scope :root_kb_articles, -> { kb_articles.where(parent_id: nil) }
    scope :ordered, -> { order(:position, :title) }

    def published?
      status == "published" && (published_at.blank? || published_at <= Time.current)
    end

    def blog_post?
      page_type == "blog_post"
    end

    def kb_article?
      page_type == "kb_article"
    end

    def glossary_term?
      page_type == "glossary_term"
    end

    def layout_name
      layout.presence || site.layout_name
    end

    def component_validation_errors
      ComponentValidator.new.errors_for(self)
    end

    private

    def published_components_are_valid
      return unless status == "published"

      component_validation_errors.each { |message| errors.add(:markdown, message) }
    end

    def parent_is_valid_knowledge_base_article
      return unless parent

      errors.add(:parent, "cannot be the page itself") if parent == self
      errors.add(:parent, "must belong to the same site") if parent.site_id != site_id
      errors.add(:parent, "can only be set for knowledge base articles") unless kb_article?
      errors.add(:parent, "must be a knowledge base article") unless parent.kb_article?
      errors.add(:parent, "cannot create a circular hierarchy") if parent_ancestor?(self)
    end

    def parent_ancestor?(candidate)
      ancestor = parent
      while ancestor
        return true if ancestor == candidate

        ancestor = ancestor.parent
      end
      false
    end

    def generate_slug
      self.slug = title.to_s.parameterize if slug.blank?
    end

    def normalize_path
      self.path = "/" if path.blank?
      self.path = "/#{path}" unless path.start_with?("/")
      self.path = path.squeeze("/")
      self.path = path.delete_suffix("/") unless path == "/"
    end
  end
end
