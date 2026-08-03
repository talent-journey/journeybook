module Journeybook
  class ComponentParser
    HIDDEN_PROP = :journeybook_hidden

    ParsedComponent = Data.define(:name, :props, :source, :token) do
      def hidden?
        props[ComponentParser::HIDDEN_PROP] == "true"
      end
    end

    COMPONENT_PATTERN = /\{\{\s*(.*?)\s*\}\}/m
    NAME_PATTERN = /\A([a-zA-Z][\w-]*)/
    PROP_PATTERN = /([a-zA-Z_]\w*)\s*=\s*(?:"([^"]*)"|'([^']*)')/

    # @param markdown [String]
    # @return [Array<ParsedComponent>]
    def parse(markdown)
      markdown.to_s.scan(COMPONENT_PATTERN).each_with_index.filter_map do |(body), index|
        build_component(body, index)
      end
    end

    # @param markdown [String]
    # @return [Array(String, Array<ParsedComponent>)]
    def extract(markdown)
      components = []
      extracted = markdown.to_s.gsub(COMPONENT_PATTERN) do |source|
        component = build_component(Regexp.last_match(1), components.length, source: source)
        next source unless component

        components << component
        component.token
      end

      [ extracted, components ]
    end

    private

    def build_component(body, index, source: nil)
      match = body.match(NAME_PATTERN)
      return unless match

      name = match[1].tr("-", "_").to_sym
      props = body.scan(PROP_PATTERN).each_with_object({}) do |(name, double_quoted, single_quoted), parsed|
        parsed[name.to_sym] = double_quoted || single_quoted
      end
      token = "JOURNEYBOOKCOMPONENT#{index}END"

      ParsedComponent.new(name, props, source || "{{#{body}}}", token)
    end
  end
end
