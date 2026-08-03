module Journeybook
  class MediaAsset < ApplicationRecord
    IMAGE_CONTENT_TYPES = %w[image/png image/jpeg image/webp image/gif image/svg+xml].freeze

    validates :title, :storage_key, :original_filename, :content_type, :byte_size, presence: true
    validates :storage_key, uniqueness: true
    validates :content_type, inclusion: { in: IMAGE_CONTENT_TYPES }
    validates :byte_size, numericality: { greater_than: 0 }

    before_destroy :delete_storage_object

    def public_url
      Journeybook::Storage::S3Client.new.public_url(storage_key)
    end

    def tag_list
      tags.to_s.split(",").map(&:strip).reject(&:blank?)
    end

    private

    def delete_storage_object
      Journeybook::Storage::S3Client.new.delete(storage_key)
    end
  end
end
