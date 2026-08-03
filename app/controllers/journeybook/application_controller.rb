module Journeybook
  class ApplicationController < ActionController::Base
    layout "journeybook/application"

    before_action :authenticate_journeybook_admin!
    before_action :set_current_site_context
    helper_method :admin_nav_active?, :current_site, :site_context_path

    private

    attr_reader :current_site

    def set_current_site_context
      requested_site = Journeybook::Site.find_by(id: params[:site_id]) if params[:site_id].present?
      session[:journeybook_site_id] = requested_site.id if requested_site

      @current_site = Journeybook::Site.find_by(id: session[:journeybook_site_id]) || Journeybook::Site.order(:name).first
      session[:journeybook_site_id] = @current_site.id if @current_site
    end

    def site_context_path(site)
      url_for(request.query_parameters.merge(site_id: site.id))
    end

    def admin_nav_active?(section)
      case section
      when :dashboard
        controller_path == "journeybook/admin/dashboard"
      when :pages
        controller_path == "journeybook/admin/pages"
      when :sites
        controller_path == "journeybook/admin/sites"
      when :redirects
        controller_path == "journeybook/admin/redirects"
      when :components
        controller_path == "journeybook/admin/components"
      when :library
        controller_path == "journeybook/admin/media_assets"
      when :ai
        controller_path == "journeybook/admin/ai_pages"
      when :navigation
        controller_path.start_with?("journeybook/admin/navigation_")
      end
    end

    def authenticate_journeybook_admin!
      return if Journeybook.configuration.admin_authenticator.call(self)

      head :forbidden
    end
  end
end
