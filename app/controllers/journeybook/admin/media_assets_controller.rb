module Journeybook
  module Admin
    class MediaAssetsController < ApplicationController
      rescue_from Journeybook::Storage::S3Client::Error, with: :storage_error

      def index
        @media_asset = MediaAsset.new
        @media_assets = MediaAsset.order(created_at: :desc)
      end

      def new
        @media_asset = MediaAsset.new
      end

      def create
        @media_asset = MediaAsset.new(media_asset_params)
        file = params.dig(:media_asset, :file)

        unless file.respond_to?(:read)
          @media_asset.errors.add(:base, "Image file is required.")
          return render :new, status: :unprocessable_entity
        end

        unless MediaAsset::IMAGE_CONTENT_TYPES.include?(file.content_type.to_s)
          @media_asset.errors.add(:content_type, "must be PNG, JPEG, WebP, GIF, or SVG")
          return render :new, status: :unprocessable_entity
        end

        upload = Journeybook::Storage::S3Client.new.upload(file)
        @media_asset.assign_attributes(upload.to_h)
        @media_asset.title = upload.original_filename if @media_asset.title.blank?

        if @media_asset.save
          redirect_to admin_media_assets_path, notice: "Image uploaded."
        else
          Journeybook::Storage::S3Client.new.delete(upload.storage_key)
          render :new, status: :unprocessable_entity
        end
      end

      def destroy
        MediaAsset.find(params[:id]).destroy
        redirect_to admin_media_assets_path, notice: "Image deleted."
      end

      private

      def media_asset_params
        params.fetch(:media_asset, {}).permit(:title, :alt_text, :description, :tags)
      end

      def storage_error(error)
        @media_asset ||= MediaAsset.new(media_asset_params)
        @media_asset.errors.add(:base, error.message)
        render :new, status: :unprocessable_entity
      end
    end
  end
end
