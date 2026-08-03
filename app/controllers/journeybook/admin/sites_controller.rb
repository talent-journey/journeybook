module Journeybook
  module Admin
    class SitesController < ApplicationController
      before_action :set_site, only: %i[edit update destroy]

      def index
        @sites = Site.order(:name)
      end

      def new
        @site = Site.new(default_locale: "en", path_prefix: "/", layout: Journeybook.configuration.default_layout)
      end

      def edit
      end

      def create
        @site = Site.new(site_params)

        if @site.save
          redirect_to admin_sites_path, notice: "Site created."
        else
          render :new, status: :unprocessable_entity
        end
      end

      def update
        if @site.update(site_params)
          redirect_to admin_sites_path, notice: "Site updated."
        else
          render :edit, status: :unprocessable_entity
        end
      end

      def destroy
        @site.destroy
        redirect_to admin_sites_path, notice: "Site deleted."
      end

      private

      def set_site
        @site = Site.find(params[:id])
      end

      def site_params
        params.require(:site).permit(:name, :key, :host, :path_prefix, :layout, :default_locale)
      end
    end
  end
end
