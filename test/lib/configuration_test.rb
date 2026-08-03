require "test_helper"

module Journeybook
  class ConfigurationTest < ActiveSupport::TestCase
    test "denies admin access by default" do
      configuration = Configuration.new

      refute configuration.admin_authenticator.call(nil)
    end

    test "configures HTTP basic authentication" do
      controller = Class.new do
        def authenticate_or_request_with_http_basic(_realm)
          yield "editor", "secret"
        end
      end.new
      configuration = Configuration.new

      configuration.admin_basic_auth(username: "editor", password: "secret")

      assert configuration.admin_authenticator.call(controller)
    end
  end
end
