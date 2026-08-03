require "commonmarker"

module Journeybook
  class MarkdownRenderer
    # @param markdown [String]
    # @return [String]
    def render(markdown)
      Commonmarker.to_html(markdown.to_s, options: commonmarker_options)
    rescue ArgumentError
      Commonmarker.to_html(markdown.to_s)
    end

    private

    def commonmarker_options
      {
        extension: {
          table: true,
          strikethrough: true,
          autolink: true,
          tasklist: true
        },
        render: {
          unsafe: true
        }
      }
    end
  end
end
