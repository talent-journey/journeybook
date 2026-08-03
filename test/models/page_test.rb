require "test_helper"

module Journeybook
  class PageTest < ActiveSupport::TestCase
    setup do
      @site = Site.create!(name: "Main", host: "example.test", default_locale: "en")
    end

    test "published scope includes published pages" do
      published = Page.create!(site: @site, title: "Home", slug: "home", path: "/", markdown: "# Home", status: "published", locale: "en")
      Page.create!(site: @site, title: "Draft", slug: "draft", path: "/draft", markdown: "Draft", status: "draft", locale: "en")

      assert_includes Page.published, published
      assert_equal [ published ], Page.by_slug("home")
    end

    test "rejects invalid status" do
      page = Page.new(site: @site, title: "Home", slug: "home", path: "/", markdown: "# Home", status: "deleted", locale: "en")

      refute page.valid?
      assert_includes page.errors[:status], "is not included in the list"
    end

    test "generates slug from title when blank" do
      page = Page.create!(site: @site, title: "About Our Team", path: "/about", markdown: "# About", status: "draft", locale: "en")

      assert_equal "about-our-team", page.slug
    end

    test "defaults page_type to page" do
      page = Page.create!(site: @site, title: "Home", path: "/", markdown: "# Home", status: "draft", locale: "en")

      assert_equal "page", page.page_type
      refute page.blog_post?
    end

    test "rejects invalid page_type" do
      page = Page.new(site: @site, title: "Home", path: "/", markdown: "# Home", status: "draft", locale: "en", page_type: "newsletter")

      refute page.valid?
      assert_includes page.errors[:page_type], "is not included in the list"
    end

    test "blog_posts scope returns only blog posts" do
      landing = Page.create!(site: @site, title: "Landing", slug: "landing", path: "/landing", markdown: "x", status: "draft", locale: "en", page_type: "page")
      post = Page.create!(site: @site, title: "News", slug: "news", path: "/blog/news", markdown: "x", status: "published", locale: "en", page_type: "blog_post", published_at: Time.current)

      assert_includes Page.blog_posts, post
      refute_includes Page.blog_posts, landing
      assert_includes Page.by_page_type("page"), landing
    end

    test "supports knowledge base hierarchies and glossary topics" do
      root = Page.create!(site: @site, title: "Getting started", slug: "getting-started", path: "/help/getting-started", markdown: "x", status: "draft", locale: "en", page_type: "kb_article")
      child = Page.create!(site: @site, title: "Invite team", slug: "invite-team", path: "/help/invite-team", markdown: "x", status: "draft", locale: "en", page_type: "kb_article", parent: root)
      glossary = Page.create!(site: @site, title: "Onboarding", slug: "onboarding", path: "/glossary/onboarding", markdown: "x", status: "draft", locale: "en", page_type: "glossary_term", topic: "HR")

      assert_includes Page.root_kb_articles, root
      refute_includes Page.root_kb_articles, child
      assert_equal [ child ], root.children
      assert_includes Page.glossary_terms.where(topic: "HR"), glossary
      assert root.kb_article?
      assert glossary.glossary_term?
    end

    test "requires knowledge base parents from the same site" do
      other_site = Site.create!(name: "Other", host: "other.test", default_locale: "en")
      parent = Page.create!(site: other_site, title: "Parent", slug: "parent", path: "/parent", markdown: "x", status: "draft", locale: "en", page_type: "kb_article")
      page = Page.new(site: @site, title: "Child", path: "/child", markdown: "x", status: "draft", locale: "en", page_type: "kb_article", parent: parent)

      refute page.valid?
      assert_includes page.errors[:parent], "must belong to the same site"
    end

    test "rejects circular knowledge base hierarchies" do
      root = Page.create!(site: @site, title: "Root", slug: "root", path: "/root", markdown: "x", status: "draft", locale: "en", page_type: "kb_article")
      child = Page.create!(site: @site, title: "Child", slug: "child", path: "/child", markdown: "x", status: "draft", locale: "en", page_type: "kb_article", parent: root)

      root.parent = child

      refute root.valid?
      assert_includes root.errors[:parent], "cannot create a circular hierarchy"
    end
  end
end
