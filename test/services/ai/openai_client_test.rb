require "test_helper"

module Journeybook
  module Ai
    class OpenaiClientTest < ActiveSupport::TestCase
      setup do
        @original_api_key = Journeybook.configuration.openai_api_key
        @original_model = Journeybook.configuration.openai_model
        @original_env_api_key = ENV["OPENAI_API_KEY"]
      end

      teardown do
        Journeybook.configuration.openai_api_key = @original_api_key
        Journeybook.configuration.openai_model = @original_model
        ENV["OPENAI_API_KEY"] = @original_env_api_key
      end

      test "uses configured OpenAI API key" do
        Journeybook.configuration.openai_api_key = "configured-key"
        ENV["OPENAI_API_KEY"] = "env-key"

        request = OpenaiClient.new.send(:build_request, "Write a page")

        assert_equal "Bearer configured-key", request["Authorization"]
      end

      test "falls back to OPENAI_API_KEY" do
        Journeybook.configuration.openai_api_key = nil
        ENV["OPENAI_API_KEY"] = "env-key"

        request = OpenaiClient.new.send(:build_request, "Write a page")

        assert_equal "Bearer env-key", request["Authorization"]
      end

      test "uses configured OpenAI model" do
        Journeybook.configuration.openai_model = "gpt-5.4-mini"

        request = OpenaiClient.new(api_key: "key").send(:build_request, "Write a page")
        body = JSON.parse(request.body)

        assert_equal "gpt-5.4-mini", body["model"]
      end
    end
  end
end
