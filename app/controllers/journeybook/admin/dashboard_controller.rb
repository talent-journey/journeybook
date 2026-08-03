module Journeybook
  module Admin
    class DashboardController < ApplicationController
      def show
        @site_count = Site.count
        @page_count = current_site ? current_site.pages.count : 0
        @published_page_count = current_site ? current_site.pages.published.count : 0
        @component_count = Journeybook.components.for_site(current_site).count
        @recent_pages = current_site ? current_site.pages.includes(:site).order(updated_at: :desc).limit(5) : Page.none
      end
    end
  end
end
