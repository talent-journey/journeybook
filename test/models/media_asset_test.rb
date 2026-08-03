require "test_helper"

module Journeybook
  class MediaAssetTest < ActiveSupport::TestCase
    setup do
      @original_public_base_url = Journeybook.configuration.s3_public_base_url
      Journeybook.configuration.s3_public_base_url = "https://cdn.example.test/assets"
    end

    teardown do
      Journeybook.configuration.s3_public_base_url = @original_public_base_url
    end

    test "requires an image content type" do
      asset = MediaAsset.new(title: "Document", storage_key: "journeybook/media/doc.txt", original_filename: "doc.txt", content_type: "text/plain", byte_size: 12)

      refute asset.valid?
      assert_includes asset.errors[:content_type], "is not included in the list"
    end

    test "builds public url from configured base url" do
      asset = MediaAsset.new(storage_key: "journeybook/media/image.png")

      assert_equal "https://cdn.example.test/assets/journeybook/media/image.png", asset.public_url
    end

    test "deletes storage object before destroy" do
      deleted = []
      fake_client = Class.new do
        define_method(:initialize) { |deleted_keys| @deleted_keys = deleted_keys }
        define_method(:delete) { |storage_key| @deleted_keys << storage_key }
      end.new(deleted)
      original_new = Journeybook::Storage::S3Client.method(:new)
      Journeybook::Storage::S3Client.define_singleton_method(:new) { fake_client }
      asset = MediaAsset.create!(title: "Hero", storage_key: "journeybook/media/hero.png", original_filename: "hero.png", content_type: "image/png", byte_size: 12)

      asset.destroy

      assert_equal [ "journeybook/media/hero.png" ], deleted
    ensure
      Journeybook::Storage::S3Client.define_singleton_method(:new, original_new)
    end
  end
end
