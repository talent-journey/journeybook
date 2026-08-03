require "json"
require "uri"

module Journeybook
  class ComponentValidator
    def initialize(parser: ComponentParser.new, registry: Journeybook.components)
      @parser = parser
      @registry = registry
    end

    def errors_for(page)
      components = @registry.for_site(page.site)

      @parser.parse(page.markdown).flat_map.with_index do |component, index|
        validate_component(component, index, components.registered(component.name))
      end
    end

    private

    def validate_component(component, index, registration)
      label = "Component #{index + 1} (#{component.name})"
      return [ "#{label} is not registered for this site." ] unless registration

      schema = registration.normalized_props
      props = component.props.except(ComponentParser::HIDDEN_PROP)
      errors = props.keys.filter_map do |name|
        "#{label} has an unknown prop: #{name}." unless schema.key?(name) || target_prop?(name, schema)
      end

      schema.each do |name, config|
        value = props[name].to_s
        errors << "#{label} is missing required prop: #{name}." if config[:required] && value.blank?
        errors.concat(validate_collection(label, name, value, config)) if value.present? && config[:type] == :collection
        errors << "#{label} has an invalid #{config[:type]} prop: #{name}." if value.present? && invalid_value?(value, config)
      end

      errors
    end

    def validate_collection(label, name, value, config)
      items = JSON.parse(value)
      return [ "#{label} has an invalid collection prop: #{name}." ] unless items.is_a?(Array)

      errors = []
      errors << "#{label} needs at least #{config[:min]} #{name} item(s)." if items.length < config[:min]
      errors << "#{label} allows at most #{config[:max]} #{name} item(s)." if config[:max] && items.length > config[:max]

      items.each_with_index do |item, index|
        errors.concat(validate_collection_item(label, name, item, index, config[:item]))
      end
      errors
    rescue JSON::ParserError
      [ "#{label} has an invalid collection prop: #{name}." ]
    end

    def validate_collection_item(label, name, item, index, schema)
      item_label = "#{label} #{name} item #{index + 1}"
      return [ "#{item_label} must be an object." ] unless item.is_a?(Hash)

      props = item.deep_symbolize_keys
      errors = props.keys.filter_map do |key|
        "#{item_label} has an unknown prop: #{key}." unless schema.key?(key) || target_prop?(key, schema)
      end

      schema.each do |key, config|
        value = props[key].to_s
        errors << "#{item_label} is missing required prop: #{key}." if config[:required] && value.blank?
        errors << "#{item_label} has an invalid #{config[:type]} prop: #{key}." if value.present? && invalid_value?(value, config)
      end
      errors
    end

    def invalid_value?(value, config)
      case config[:type]
      when :select
        !config[:options].include?(value)
      when :image, :video
        !http_url?(value) && !(config[:icons] && icon_reference?(value, config[:icons]))
      when :url
        !relative_or_http_url?(value) && !page_reference?(value)
      else
        false
      end
    end

    def http_url?(value)
      uri = URI.parse(value)
      uri.is_a?(URI::HTTP) && uri.host.present?
    rescue URI::InvalidURIError
      false
    end

    def relative_or_http_url?(value)
      value.start_with?("/", "#") || http_url?(value)
    end

    def page_reference?(value)
      value.match?(%r{\Ajourneybook://page/\d+\z})
    end

    def icon_reference?(value, icon_config)
      style, color, identifier = value.to_s.match(%r{\Aicon:([a-z0-9-]+):([a-z0-9-]+):([a-z0-9-]+)\z})&.captures
      style.in?(icon_config[:styles]) && color.in?(icon_config[:colors]) && identifier.present?
    end

    def target_prop?(name, schema)
      name.to_s.end_with?("_target") && schema.key?(name.to_s.delete_suffix("_target").to_sym)
    end
  end
end
