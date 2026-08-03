module Journeybook
  module PublicPages
    extend ActiveSupport::Concern

    included do
      helper Journeybook::NavigationHelper
      helper_method :journeybook_page, :journeybook_html, :journeybook_site
    end

    def show
      resolver = Journeybook::PageResolver.from_request(request, path: params[:path])
      @journeybook_page = resolver.call

      redirect = Journeybook::Redirect.for_path(params[:path]) if @journeybook_page.blank? && resolver.site
      return redirect_to(redirect.to, status: redirect.status_code) if redirect

      return render_not_found unless @journeybook_page

      @journeybook_site = @journeybook_page.site
      @journeybook_html = Journeybook::PageRenderer.new.render(@journeybook_page, form_authenticity_token: form_authenticity_token)
    end

    private

    attr_reader :journeybook_page, :journeybook_html, :journeybook_site

    def render_not_found
      render file: Rails.public_path.join("404.html"), layout: false, status: :not_found
    end
  end
end
