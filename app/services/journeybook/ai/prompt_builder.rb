require "json"

module Journeybook
  module Ai
    class PromptBuilder
      def initialize(components: Journeybook.components, site: nil, style_prompt: nil, template: nil, media_assets: MediaAsset.order(created_at: :desc).limit(25))
        @components = components
        @site = site
        @style_prompt = style_prompt
        @template = template
        @media_assets = media_assets
      end

      def build(user_prompt:)
        <<~PROMPT
          You are designing a Journeybook CMS page for a Rails website.

          Return exactly one complete Markdown document. Do not wrap it in code fences. Do not explain the result.

          User request:
          #{user_prompt}

          Style instructions:
          #{style_instructions}

           Current Journeybook context:
           #{site_context}

           Template instructions:
           #{template_instructions}

           Available Journeybook components:
          #{component_reference}

          Available image library:
          #{image_library_reference}

          Rules:
          - Use component tags only for page content.
          - Do not write Markdown headings, paragraphs, lists, links, raw HTML, or standalone text outside component tags.
          - The only allowed non-component content is frontmatter, if frontmatter is needed.
          - Copy/text may appear inside component prop values.
          - Use only the registered components listed above.
          - Component syntax is: {{ component_name prop="value" other_prop="value" }}
          - Do not invent unsupported component names.
          - Use image library URLs only when a registered component has a suitable image prop.
          - Prefer matching alt text from the image library.
          - Do not invent image URLs.
          - Do not output raw Markdown image syntax.
          - Fill component props with concise production-ready copy.
          - Keep the page coherent and ready for a public website.
        PROMPT
      end

      private

      def style_instructions
        @style_prompt.presence || "No additional style instructions."
      end

      def site_context
        return "No site context selected." unless @site

        <<~TEXT
          - Name: #{@site.name}
          - Key: #{@site.key}
          - Path prefix: #{@site.path_prefix}
          - Layout: #{@site.layout_name}
        TEXT
      end

      def component_reference
        components = available_components
        return "No components are registered. Return only frontmatter or an empty document." if components.none?

        components.map do |component|
          props = component.normalized_props
          prop_lines = props.map do |name, prop|
            collection_reference(name, prop) || "    - #{name} (#{prop_type_reference(prop)}): #{prop[:description].presence || prop[:label]}"
          end.join("\n")

          <<~TEXT
            - #{component.name}
              Description: #{component.metadata.fetch(:description, "No description provided")}
              Props:
          #{prop_lines.presence || "    - none"}
              Example: {{ #{component.name} #{props.map { |name, prop| prop_example(name, prop) }.join(" ")} }}
          TEXT
        end.join("\n")
      end

      def template_instructions
        return "No template selected. Choose the component layout that best fits the request." unless @template

        <<~TEXT
          - Template: #{@template.name}
          - Editorial purpose: #{@template.description}
          - Page type: #{@template.page_type}
          - Use only the template components, in exactly this order, and include each one exactly once.
          - Replace starter copy with production-ready content that answers the user request.
          - Do not add, remove, or reorder components.
          Template layout:
          #{@template.markdown}
        TEXT
      end

      def available_components
        return @components unless @template

        names = ComponentParser.new.parse(@template.markdown).map(&:name).uniq
        @components.select { |component| component.name.in?(names) }
      end

      def collection_reference(name, prop)
        return unless prop[:type] == :collection

        item_props = prop[:item].map do |item_name, item_prop|
          "#{item_name} (#{prop_type_reference(item_prop)})"
        end.join(", ")
        count = prop[:max] ? "#{prop[:min]}-#{prop[:max]}" : "at least #{prop[:min]}"
        "    - #{name} (collection, #{count} items): #{item_props}"
      end

      def prop_example(name, prop)
        return %(#{name}="#{prop[:options]&.first || "..."}") unless prop[:type] == :collection

        item = prop[:item].each_with_object({}) do |(item_name, item_prop), values|
          values[item_name] = item_prop[:options]&.first || "..."
        end
        %(#{name}='#{JSON.generate([ item ])}')
      end

      def prop_type_reference(prop)
        return prop[:type].to_s unless prop[:type] == :select

        "select: #{prop[:options].join(", ")}"
      end

      def image_library_reference
        assets = @media_assets.to_a
        return "No images are available." if assets.none?

        assets.map do |asset|
          <<~TEXT
            - Title: #{asset.title}
              Alt text: #{asset.alt_text.presence || "No alt text provided"}
              URL: #{asset.public_url}
              Tags: #{asset.tags.presence || "none"}
          TEXT
        end.join("\n")
      end
    end
  end
end
