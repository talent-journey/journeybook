require "json"

module Journeybook
  class ComponentRenderer
    # @param registry [Journeybook::ComponentRegistry]
    def initialize(registry: Journeybook.components)
      @registry = registry
    end

    # @param component [Journeybook::ComponentParser::ParsedComponent]
    # @return [String]
    def render(component, page: nil)
      return "" if component.hidden?

      registration = @registry.registered(component.name)
      component_class = @registry.fetch(component.name)
      schema = registration.normalized_props
      props = coerce_props(component.props.except(ComponentParser::HIDDEN_PROP), schema, page)
      link_targets = link_targets(component.props, schema, page)

      html = if component_class.respond_to?(:render)
        if accepts_keyword?(component_class.method(:render), :page)
          component_class.render(**props, page: page).to_s
        else
          component_class.render(**props).to_s
        end
      elsif accepts_keyword?(component_class.instance_method(:initialize), :page)
        component_class.new(**props, page: page).render.to_s
      else
        component_class.new(**props).render.to_s
      end
      apply_link_targets(html, link_targets)
    end

    private

    def coerce_props(props, schema, page)
        props.each_with_object({}) do |(name, value), coerced|
          next if target_prop?(name, schema)

          config = schema[name]
          coerced[name] = if config&.fetch(:type) == :collection
            collection_value(value, config[:item], page)
          elsif config&.fetch(:type) == :url
            resolve_url(value, page)
          else
            value
          end
        end
      end

      def collection_value(value, item_schema, page)
        JSON.parse(value).map do |item|
          item.deep_symbolize_keys.each_with_object({}) do |(name, item_value), props|
            props[name] = item_schema[name]&.fetch(:type) == :url ? resolve_url(item_value, page) : item_value
          end
        end
      rescue JSON::ParserError, NoMethodError
        []
      end

      def link_targets(props, schema, page)
        props.each_with_object({}) do |(name, value), targets|
          config = schema[name]
          if config&.fetch(:type) == :url && props["#{name}_target".to_sym] == "open_new_window"
            targets[resolve_url(value, page)] = "_blank"
          elsif config&.fetch(:type) == :collection
            collection_value(value, config[:item], page).each do |item|
              target = item[:href_target]
              targets[item[:href]] = "_blank" if target == "open_new_window" && item[:href].present?
            end
          end
        end
      end

      def apply_link_targets(html, targets)
        return html if targets.empty?

        fragment = Nokogiri::HTML5.fragment(html)
        fragment.css("a[href]").each do |link|
          next unless targets[link["href"]] == "_blank"

          link["target"] = "_blank"
          link["rel"] = "noopener noreferrer"
        end
        fragment.to_html
      end

      def resolve_url(value, page)
        match = value.to_s.match(%r{\Ajourneybook://page/(\d+)\z})
        return value unless match && page

        page.site.pages.find_by(id: match[1])&.path || value
      end

      def target_prop?(name, schema)
        name.to_s.end_with?("_target") && schema.key?(name.to_s.delete_suffix("_target").to_sym)
      end

      def accepts_keyword?(method, name)
        return false unless method.respond_to?(:parameters)

        method.parameters.any? do |type, param|
          param == name && %i[keyreq key keyrest].include?(type)
        end
      end
  end
end
