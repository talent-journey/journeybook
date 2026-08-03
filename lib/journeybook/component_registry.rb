module Journeybook
  class ComponentRegistry
    Component = Data.define(:name, :component_class, :metadata) do
      DEFAULT_PROP_TYPE = :short_text

      def schema
        {
          "name" => name.to_s,
          "description" => metadata.fetch(:description, nil),
          "props" => normalized_props.transform_keys(&:to_s).transform_values do |prop|
            {
              "type" => prop[:type].to_s,
              "label" => prop[:label],
              "description" => prop[:description],
              "required" => prop[:required]
            }.tap do |schema|
              next unless prop[:type] == :collection

              schema["min"] = prop[:min]
              schema["max"] = prop[:max]
              schema["item"] = prop[:item].transform_keys(&:to_s)
            end.tap do |schema|
              next unless prop[:type] == :select

              schema["options"] = prop[:options]
            end
          end
        }
      end

      def normalized_props
        metadata.fetch(:props, {}).each_with_object({}) do |(prop_name, config), props|
          props[prop_name.to_sym] = normalize_prop(prop_name, config)
        end
      end

      private

      def normalize_prop(prop_name, config)
        config_hash = config.is_a?(Hash) ? config.symbolize_keys : { description: config.to_s }

        {
          type: (config_hash[:type].presence || DEFAULT_PROP_TYPE).to_sym,
          label: config_hash[:label].presence || prop_name.to_s.humanize,
          description: config_hash[:description].to_s,
          required: config_hash.fetch(:required, true)
        }.tap do |prop|
          if prop[:type] == :image && config_hash[:icons]
            icon_config = config_hash[:icons].is_a?(Hash) ? config_hash[:icons].symbolize_keys : {}
            prop[:icons] = {
              styles: Array(icon_config[:styles].presence || %w[classic duotone]).map(&:to_s),
              colors: Array(icon_config[:colors]).map(&:to_s)
            }
          end
          if prop[:type] == :collection
            prop[:min] = config_hash[:min].to_i
            prop[:max] = config_hash[:max].to_i if config_hash[:max].present?
            prop[:item] = normalize_item_props(config_hash[:item])
          elsif prop[:type] == :select
            prop[:options] = Array(config_hash[:options]).map(&:to_s)
          end
        end
      end

      def normalize_item_props(item)
        item.to_h.each_with_object({}) do |(prop_name, config), props|
          props[prop_name.to_sym] = normalize_prop(prop_name, config)
        end
      end
    end

    include Enumerable

    def initialize
      @components = {}
    end

    # @param name [String, Symbol]
    # @param component_class [Class]
    # @param metadata [Hash]
    # @return [Component]
    def register(name, component_class, **metadata)
      normalized_name = normalize_name(name)
      @components[normalized_name] = Component.new(normalized_name, component_class, metadata)
    end

    # @param name [String, Symbol]
    # @return [Object]
    # @raise [Journeybook::UnknownComponentError]
    def fetch(name)
      registered = @components.fetch(normalize_name(name)) do
        raise UnknownComponentError, "Unknown Journeybook component: #{name}"
      end

      registered.component_class
    end

    # @param name [String, Symbol]
    # @return [Component, nil]
    def registered(name)
      @components[normalize_name(name)]
    end

    # @return [Array<Hash>]
    def schema
      @components.values.map(&:schema)
    end

    def for_site(site)
      return self unless site

      filtered = self.class.new
      @components.values.each do |component|
        next unless component_available_for_site?(component, site)

        filtered.register(component.name, component.component_class, **component.metadata)
      end
      filtered
    end

    def each(&block)
      @components.values.each(&block)
    end

    private

    def normalize_name(name)
      name.to_s.strip.underscore.to_sym
    end

    def component_available_for_site?(component, site)
      sites = Array(component.metadata[:sites]).map { |value| normalize_name(value) }
      sites.empty? || sites.include?(normalize_name(site.key))
    end
  end
end
