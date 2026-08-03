module Journeybook
  module Ai
    class TemplateValidator
      def initialize(parser: ComponentParser.new)
        @parser = parser
      end

      def errors_for(markdown, template)
        expected = @parser.parse(template.markdown).map(&:name)
        actual = @parser.parse(markdown).map(&:name)
        return [] if actual == expected

        [ "AI draft must use the #{template.name} template components in the approved order." ]
      end
    end
  end
end
