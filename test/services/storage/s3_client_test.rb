require "test_helper"
require "stringio"

module Journeybook
  module Storage
    class S3ClientTest < ActiveSupport::TestCase
      Config = Struct.new(:s3_bucket, :s3_region, :s3_access_key_id, :s3_secret_access_key, :s3_prefix, :s3_public_base_url)

      FakeS3 = Class.new do
        attr_reader :put_objects, :deleted_objects

        def initialize
          @put_objects = []
          @deleted_objects = []
        end

        def put_object(attributes)
          @put_objects << attributes
        end

        def delete_object(attributes)
          @deleted_objects << attributes
        end
      end

      test "uploads file content and returns metadata" do
        s3 = FakeS3.new
        config = Config.new("bucket", "eu-central-1", "key", "secret", "journeybook", "https://cdn.example.test")
        file = upload_file("Hero Image.PNG", "image/png", "image-content")

        upload = S3Client.new(configuration: config, client: s3).upload(file)

        assert_equal "Hero Image.PNG", upload.original_filename
        assert_equal "image/png", upload.content_type
        assert_equal "image-content".bytesize, upload.byte_size
        assert_match %r{\Ajourneybook/media/.+/hero-image.png\z}, upload.storage_key
        assert_equal "bucket", s3.put_objects.first[:bucket]
        assert_equal upload.storage_key, s3.put_objects.first[:key]
        assert_equal "image/png", s3.put_objects.first[:content_type]
      end

      test "deletes storage key" do
        s3 = FakeS3.new
        config = Config.new("bucket", "eu-central-1", "key", "secret", "journeybook", nil)

        S3Client.new(configuration: config, client: s3).delete("journeybook/media/image.png")

        assert_equal [ { bucket: "bucket", key: "journeybook/media/image.png" } ], s3.deleted_objects
      end

      test "builds public url from cdn base url" do
        config = Config.new("bucket", "eu-central-1", "key", "secret", "journeybook", "https://cdn.example.test/")

        assert_equal "https://cdn.example.test/journeybook/media/image.png", S3Client.new(configuration: config).public_url("journeybook/media/image.png")
      end

      private

      def upload_file(filename, content_type, content)
        file = StringIO.new(content)
        file.define_singleton_method(:original_filename) { filename }
        file.define_singleton_method(:content_type) { content_type }
        file
      end
    end
  end
end
