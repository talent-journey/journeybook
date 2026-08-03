module Journeybook
  module Admin
    class ComponentsController < ApplicationController
      def index
        @components = Journeybook.components.for_site(current_site).to_a
        @selected_component = selected_component
      end

      def preview
        @components = Journeybook.components.for_site(current_site).to_a
        @selected_component = component_for(params[:component])
        return head :not_found unless @selected_component

        @preview_props = preview_props(@selected_component)
        @preview_html = render_preview(@selected_component, @preview_props)

        render :preview, layout: preview_layout
      rescue StandardError => error
        @preview_error = "#{error.class}: #{error.message}"
        render :preview, layout: preview_layout, status: :unprocessable_entity
      end

      private

      def selected_component
        return if @components.empty?

        component_for(params[:component]) || @components.first
      end

      def component_for(name)
        @components.find { |component| component.name.to_s == name.to_s }
      end

      def preview_props(component)
        component_class = component.component_class
        return component_class.preview_props if component_class.respond_to?(:preview_props)

        raise ArgumentError, "#{component.name} must define .preview_props for its component preview."
      end

      def render_preview(component, props)
        component_class = component.component_class
        html = if component_class.respond_to?(:render)
          component_class.render(**props)
        else
          component_class.new(**props).render
        end
        HtmlSanitizer.new.sanitize(html)
      end

      def preview_layout
        current_site&.layout_name || Journeybook.configuration.default_layout
      end
    end
  end
end
