module Journeybook
  class Redirect < ApplicationRecord
    VALID_STATUS_CODES = [ 301, 302, 307, 308 ].freeze

    before_validation :normalize_paths

    validates :from, :to, :status_code, presence: true
    validates :from, uniqueness: true
    validates :from, :to, format: { with: %r{\A/(?!/)} }
    validates :status_code, inclusion: { in: VALID_STATUS_CODES }

    def self.for_path(path)
      find_by(from: normalize_path(path))
    end

    def self.normalize_path(path)
      value = path.to_s.strip
      value = "/#{value}" unless value.start_with?("/")
      value = value.squeeze("/")
      value = value.delete_suffix("/") unless value == "/"
      value.presence || "/"
    end

    private

    def normalize_paths
      self.from = self.class.normalize_path(from)
      self.to = self.class.normalize_path(to)
    end
  end
end
