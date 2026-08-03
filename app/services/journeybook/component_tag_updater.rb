require "json"

module Journeybook
  class ComponentTagUpdater
    def initialize(parser: ComponentParser.new)
      @parser = parser
    end

    def update(markdown, index, props)
      components = @parser.parse(markdown)
      component = components.fetch(index)
      replace_component(markdown, index, component.name, component.props.merge(normalized_props(props)))
    end

    def move(markdown, index, direction)
      tags = component_tags(markdown)
      tag = fetch_tag(tags, index)
      target_index = direction.to_s == "up" ? index - 1 : index + 1
      target = fetch_tag(tags, target_index)

      replace_sources(markdown, {
        tag => target.source,
        target => tag.source
      })
    end

    def reorder(markdown, indexes)
      tags = component_tags(markdown)
      indexes = Array(indexes).map(&:to_i)
      raise ArgumentError unless indexes.sort == (0...tags.length).to_a

      replace_sources(markdown, tags.zip(indexes.map { |index| tags.fetch(index).source }).to_h)
    end

    def delete(markdown, index)
      tag = fetch_tag(component_tags(markdown), index)
      replace_sources(markdown, tag => "").gsub(/\n{3,}/, "\n\n")
    end

    def toggle_visibility(markdown, index)
      components = @parser.parse(markdown)
      component = components.fetch(index)
      props = component.props.dup

      if component.hidden?
        props.delete(ComponentParser::HIDDEN_PROP)
      else
        props[ComponentParser::HIDDEN_PROP] = "true"
      end

      replace_component(markdown, index, component.name, props)
    end

    def append(markdown, name, props = {})
      source = serialize(name, normalized_props(props))
      body = markdown.to_s.rstrip

      return source if body.blank?

      "#{body}\n\n#{source}"
    end

    private

    ComponentTag = Data.define(:source, :begin_index, :end_index)

    def fetch_tag(tags, index)
      raise IndexError if index.negative? || index >= tags.length

      tags.fetch(index)
    end

    def component_tags(markdown)
      markdown.to_s.enum_for(:scan, ComponentParser::COMPONENT_PATTERN).map do
        match = Regexp.last_match
        ComponentTag.new(match[0], match.begin(0), match.end(0))
      end
    end

    def replace_component(markdown, index, name, props)
      updated_source = serialize(name, props)
      current_index = -1

      markdown.to_s.gsub(ComponentParser::COMPONENT_PATTERN) do |source|
        current_index += 1
        current_index == index ? updated_source : source
      end
    end

    def replace_sources(markdown, replacements)
      replacements.sort_by { |tag, _source| tag.begin_index }.reverse_each.reduce(markdown.to_s.dup) do |updated, (tag, source)|
        updated[tag.begin_index...tag.end_index] = source
        updated
      end
    end

    def normalized_props(props)
      props.to_h.each_with_object({}) do |(name, value), normalized|
        normalized[name.to_sym] = parsed_collection(value) || value.to_s
      end
    end

    def serialize(name, props)
      serialized_props = props.map do |key, value|
        %(#{key}=#{serialize_value(value)})
      end

      "{{ #{([ name ] + serialized_props).join(" ")} }}"
    end

    def escape_value(value)
      value.to_s.gsub('"', "'")
    end

    def serialize_value(value)
      collection = parsed_collection(value)
      return %('#{JSON.generate(collection).gsub("'", "\\u0027")}') if collection

      %("#{escape_value(value)}")
    end

    def parsed_collection(value)
      return value if value.is_a?(Array) || value.is_a?(Hash)
      return unless value.to_s.strip.start_with?("[", "{")

      parsed = JSON.parse(value)
      parsed if parsed.is_a?(Array) || parsed.is_a?(Hash)
    rescue JSON::ParserError
      nil
    end
  end
end
