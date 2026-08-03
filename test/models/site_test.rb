require "test_helper"

module Journeybook
  class SiteTest < ActiveSupport::TestCase
    test "requires name host and default locale" do
      site = Site.new(default_locale: nil)

      refute site.valid?
      assert_includes site.errors[:name], "can't be blank"
      assert_includes site.errors[:host], "can't be blank"
      assert_includes site.errors[:default_locale], "can't be blank"
    end

    test "builds public paths within a path-prefixed site" do
      site = Site.create!(name: "Blog", host: "example.test", path_prefix: "/blog", default_locale: "en")
      page = site.pages.create!(title: "Post", slug: "post", path: "/post", markdown: "# Post", status: "published", locale: "en")
      root = site.pages.create!(title: "Index", slug: "index", path: "/", markdown: "# Index", status: "published", locale: "en")

      assert_equal "/blog/post", site.public_path_for(page)
      assert_equal "/blog", site.public_path_for(root)
    end
  end
end
