module Journeybook
  module NavigationHelper
    def journeybook_menu(key, site: nil)
      site ||= @journeybook_site || @journeybook_page&.site
      return unless site

      @journeybook_navigation_menus ||= {}
      @journeybook_navigation_menus[[ site.id, key.to_s ]] ||= site.navigation_menus.includes(items: :page).find_by(key: key.to_s)
    end
  end
end
