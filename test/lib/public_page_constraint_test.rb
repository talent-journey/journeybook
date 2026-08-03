require "test_helper"

module Journeybook
  class PublicPageConstraintTest < ActiveSupport::TestCase
    test "matches html get requests" do
      request = ActionDispatch::TestRequest.create
      request.request_method = "GET"
      request.path_info = "/about"

      assert PublicPageConstraint.new.matches?(request)
    end

    test "does not match reserved Rails paths" do
      request = ActionDispatch::TestRequest.create
      request.request_method = "GET"
      request.path_info = "/rails/active_storage/blobs/file"

      assert_not PublicPageConstraint.new.matches?(request)
    end
  end
end
