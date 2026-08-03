require "aws-sdk-s3"
require "digest"
require "securerandom"

module Journeybook
  module Storage
    class S3Client
      class Error < Journeybook::Error; end

      Upload = Data.define(:storage_key, :original_filename, :content_type, :byte_size, :checksum)

      def initialize(configuration: Journeybook.configuration, client: nil)
        @configuration = configuration
        @client = client
      end

      def upload(file)
        raise Error, "Image file is required." unless file.respond_to?(:read)

        content = file.read
        file.rewind if file.respond_to?(:rewind)
        original_filename = File.basename(file.original_filename.to_s)
        content_type = file.content_type.to_s
        storage_key = build_storage_key(original_filename)

        s3_client.put_object(
          bucket: bucket,
          key: storage_key,
          body: content,
          content_type: content_type
        )

        Upload.new(
          storage_key: storage_key,
          original_filename: original_filename,
          content_type: content_type,
          byte_size: content.bytesize,
          checksum: Digest::SHA256.hexdigest(content)
        )
      end

      def delete(storage_key)
        return if storage_key.blank?

        s3_client.delete_object(bucket: bucket, key: storage_key)
      end

      def public_url(storage_key)
        base_url = @configuration.s3_public_base_url.to_s.delete_suffix("/")
        return "#{base_url}/#{storage_key}" if base_url.present?

        raise Error, "Journeybook S3 bucket and region are required." if bucket.blank? || region.blank?

        "https://#{bucket}.s3.#{region}.amazonaws.com/#{storage_key}"
      end

      private

      def s3_client
        @client ||= begin
          raise Error, "Journeybook S3 bucket is missing. Set config.s3_bucket." if bucket.blank?
          raise Error, "Journeybook S3 region is missing. Set config.s3_region." if region.blank?
          raise Error, "Journeybook S3 access key is missing. Set config.s3_access_key_id." if @configuration.s3_access_key_id.blank?
          raise Error, "Journeybook S3 secret key is missing. Set config.s3_secret_access_key." if @configuration.s3_secret_access_key.blank?

          Aws::S3::Client.new(
            region: region,
            access_key_id: @configuration.s3_access_key_id,
            secret_access_key: @configuration.s3_secret_access_key
          )
        end
      end

      def build_storage_key(original_filename)
        filename = sanitize_filename(original_filename.presence || "image")
        [ prefix, "media", SecureRandom.uuid, filename ].reject(&:blank?).join("/")
      end

      def sanitize_filename(filename)
        filename.to_s.downcase.gsub(/[^a-z0-9.\-_]+/, "-").delete_prefix("-").delete_suffix("-").presence || "image"
      end

      def prefix
        @configuration.s3_prefix.to_s.strip.delete_prefix("/").delete_suffix("/")
      end

      def bucket
        @configuration.s3_bucket
      end

      def region
        @configuration.s3_region
      end
    end
  end
end
