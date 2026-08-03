require "test_helper"

module Journeybook
  class PageResolverTest < ActiveSupport::TestCase
    setup do
      @site = Site.create!(name: "Test Site", host: "example.test", default_locale: "en")
      @page = @site.pages.create!(
        title: "Home",
        slug: "home",
        path: "/",
        markdown: "# Home",
        status: "published",
        locale: "en"
      )
    end

    test "resolves a published page by host and path" do
      assert_equal @page, PageResolver.new(host: "example.test", path: "/").call
    end

    test "normalizes missing leading slash and trailing slash" do
      page = @site.pages.create!(
        title: "About",
        slug: "about",
        path: "/about",
        markdown: "# About",
        status: "published",
        locale: "en"
      )

      assert_equal page, PageResolver.new(host: "example.test", path: "about/").call
    end

    test "does not resolve a page when host is unknown" do
      assert_nil PageResolver.new(host: "unknown.test", path: "/").call
    end

    test "resolves pages relative to the matching site path prefix" do
      blog = Site.create!(name: "Blog", key: "blog", host: "example.test", path_prefix: "/blog", default_locale: "en")
      post = blog.pages.create!(
        title: "Post",
        slug: "post",
        path: "/post",
        markdown: "# Post",
        status: "published",
        locale: "en"
      )

      assert_equal post, PageResolver.new(host: "example.test", path: "/blog/post").call
    end

    test "prefers the longest path prefix for sites on the same host" do
      docs = Site.create!(name: "Docs", key: "docs", host: "example.test", path_prefix: "/docs", default_locale: "en")
      api = Site.create!(name: "API Docs", key: "api_docs", host: "example.test", path_prefix: "/docs/api", default_locale: "en")

      docs_page = docs.pages.create!(title: "API Reference", slug: "api-reference", path: "/api-reference", markdown: "# Docs", status: "published", locale: "en")
      api_page = api.pages.create!(title: "API Home", slug: "home", path: "/", markdown: "# API", status: "published", locale: "en")

      assert_equal api_page, PageResolver.new(host: "example.test", path: "/docs/api").call
      assert_equal docs_page, PageResolver.new(host: "example.test", path: "/docs/api-reference").call
    end
  end
end
