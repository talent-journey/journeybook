require "test_helper"

module Journeybook
  class NavigationItemTest < ActiveSupport::TestCase
    setup do
      @site = Site.create!(name: "Main", host: "example.test", default_locale: "en")
      @menu = @site.navigation_menus.create!(key: "footer_product", title: "Product")
      @page = @site.pages.create!(title: "About", slug: "about", path: "/about", markdown: "# About", status: "published", locale: "en")
    end

    test "requires a page or external URL" do
      item = @menu.items.build(label: "About")

      refute item.valid?
      assert_includes item.errors[:base], "Select either a page or an external URL"
    end

    test "uses the page path for page destinations" do
      item = @menu.items.create!(label: "About", page: @page)

      assert_equal "/about", item.href
      assert item.displayable?
    end

    test "returns a blank target unless configured to open a new window" do
      item = @menu.items.create!(label: "External", external_url: "https://example.test")

      assert_nil item.target
      item.update!(open_in_new_window: true)
      assert_equal "_blank", item.target
    end

    test "does not display an item for an unpublished page" do
      @page.update!(status: "draft")
      item = @menu.items.create!(label: "About", page: @page)

      refute item.displayable?
    end

    test "rejects pages from another site" do
      other_site = Site.create!(name: "Other", host: "other.test", default_locale: "en")
      other_page = other_site.pages.create!(title: "Other", slug: "other", path: "/other", markdown: "# Other", status: "published", locale: "en")
      item = @menu.items.build(label: "Other", page: other_page)

      refute item.valid?
      assert_includes item.errors[:page], "must belong to the same site as the menu"
    end
  end
end
