require "test_helper"

module Journeybook
  module Ai
    class MarkdownGeneratorTest < ActiveSupport::TestCase
      FakePromptBuilder = Data.define(:prompt) do
        def build(user_prompt:)
          "#{prompt}: #{user_prompt}"
        end
      end

      FakeClient = Data.define(:responses) do
        def complete(prompt)
          responses << prompt
          "# Generated"
        end
      end

      test "builds prompt and returns client markdown" do
        responses = []
        generator = MarkdownGenerator.new(prompt_builder: FakePromptBuilder.new("system"), client: FakeClient.new(responses))

        assert_equal "# Generated", generator.generate(prompt: "page")
        assert_equal [ "system: page" ], responses
      end
    end
  end
end
