require "test_helper"

module Journeybook
  class RedirectTest < ActiveSupport::TestCase
    test "allows standard redirect status codes" do
      redirect = Redirect.new(from: "/old", to: "/new", status_code: 301)

      assert redirect.valid?
    end

    test "rejects invalid redirect status codes" do
      redirect = Redirect.new(from: "/old", to: "/new", status_code: 200)

      refute redirect.valid?
      assert_includes redirect.errors[:status_code], "is not included in the list"
    end

    test "normalizes source and target paths" do
      redirect = Redirect.create!(from: "old-page/", to: "new-page/", status_code: 301)

      assert_equal "/old-page", redirect.from
      assert_equal "/new-page", redirect.to
      assert_equal redirect, Redirect.for_path("/old-page/")
    end
  end
end
