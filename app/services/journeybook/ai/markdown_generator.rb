module Journeybook
  module Ai
    class MarkdownGenerator
      def initialize(site: nil, style_prompt: nil, template: nil, prompt_builder: nil, client: OpenaiClient.new)
        prompt_builder ||= PromptBuilder.new(components: Journeybook.components.for_site(site), site: site, style_prompt: style_prompt, template: template)
        @prompt_builder = prompt_builder
        @client = client
      end

      def generate(prompt:)
        @client.complete(@prompt_builder.build(user_prompt: prompt))
      end
    end
  end
end
