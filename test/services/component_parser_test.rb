require "test_helper"

module Journeybook
  class ComponentParserTest < ActiveSupport::TestCase
    test "parses inline components" do
      component = ComponentParser.new.parse('{{ hero title="Hello" }}').first

      assert_equal :hero, component.name
      assert_equal({ title: "Hello" }, component.props)
    end

    test "parses multiline components" do
      markdown = <<~MARKDOWN
        {{ hero
        title="Hello"
        subtitle="World"
        }}
      MARKDOWN

      component = ComponentParser.new.parse(markdown).first

      assert_equal :hero, component.name
      assert_equal({ title: "Hello", subtitle: "World" }, component.props)
    end

    test "parses single-quoted collection props" do
      component = ComponentParser.new.parse(%({{ feature_grid items='[{"title":"One"}]' }})).first

      assert_equal '[{"title":"One"}]', component.props[:items]
    end

    test "extracts components into tokens" do
      markdown, components = ComponentParser.new.extract("# Hello\n{{ hero }}")

      assert_includes markdown, "JOURNEYBOOKCOMPONENT0END"
      assert_equal 1, components.length
      assert_equal :hero, components.first.name
    end
  end
end
