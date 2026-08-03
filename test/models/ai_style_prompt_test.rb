require "test_helper"

module Journeybook
  class AiStylePromptTest < ActiveSupport::TestCase
    test "requires a unique name and prompt" do
      style_prompt = AiStylePrompt.create!(name: "Feature page", prompt: "Use feature cards.")
      duplicate = AiStylePrompt.new(name: style_prompt.name, prompt: "Different instructions")

      refute duplicate.valid?
      assert_includes duplicate.errors[:name], "has already been taken"
    end
  end
end
