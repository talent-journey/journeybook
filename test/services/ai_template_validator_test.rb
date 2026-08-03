require "test_helper"

module Journeybook
  module Ai
    class TemplateValidatorTest < ActiveSupport::TestCase
      setup do
        @template = PageTemplateRegistry::Template.new(:blog_post, {
          name: "Blog post",
          markdown: "{{ article_hero }}\n\n{{ text text=\"Start here\" }}"
        })
      end

      test "accepts the approved component sequence" do
        errors = TemplateValidator.new.errors_for("{{ article_hero }}\n\n{{ text text=\"Generated article\" }}", @template)

        assert_empty errors
      end

      test "rejects added, removed, or reordered template components" do
        validator = TemplateValidator.new

        assert_equal [ "AI draft must use the Blog post template components in the approved order." ], validator.errors_for("{{ text text=\"Generated article\" }}\n\n{{ article_hero }}", @template)
        assert_equal [ "AI draft must use the Blog post template components in the approved order." ], validator.errors_for("{{ article_hero }}", @template)
      end
    end
  end
end
