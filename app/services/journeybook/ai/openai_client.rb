require "json"
require "net/http"

module Journeybook
  module Ai
    class OpenaiClient
      class Error < Journeybook::Error; end

      ENDPOINT = URI("https://api.openai.com/v1/responses")

      def initialize(api_key: Journeybook.configuration.openai_api_key.presence || ENV["OPENAI_API_KEY"], model: Journeybook.configuration.openai_model)
        @api_key = api_key
        @model = model
      end

      def complete(prompt)
        raise Error, "OpenAI API key is missing. Set config.openai_api_key or OPENAI_API_KEY." if @api_key.blank?

        response = Net::HTTP.start(ENDPOINT.host, ENDPOINT.port, use_ssl: true) do |http|
          http.request(build_request(prompt))
        end

        body = JSON.parse(response.body)
        raise Error, openai_error(body, response) unless response.is_a?(Net::HTTPSuccess)

        extract_text(body)
      rescue JSON::ParserError
        raise Error, "OpenAI returned an invalid JSON response."
      end

      private

      def build_request(prompt)
        request = Net::HTTP::Post.new(ENDPOINT)
        request["Authorization"] = "Bearer #{@api_key}"
        request["Content-Type"] = "application/json"
        request.body = JSON.dump({ model: @model, input: prompt })
        request
      end

      def extract_text(body)
        text = body["output_text"].presence || body.fetch("output", []).flat_map { |item| item.fetch("content", []) }.filter_map { |content| content["text"] }.join("\n")
        text = text.to_s.strip
        raise Error, "OpenAI returned an empty response." if text.blank?

        text
      end

      def openai_error(body, response)
        body.dig("error", "message").presence || "OpenAI request failed with HTTP #{response.code}."
      end
    end
  end
end
