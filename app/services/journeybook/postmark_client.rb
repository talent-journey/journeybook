require "json"
require "net/http"
require "uri"

module Journeybook
  class PostmarkClient
    class Error < StandardError; end

    ENDPOINT = URI("https://api.postmarkapp.com/email")

    def initialize(api_key: Journeybook.configuration.postmark_api_key, endpoint: ENDPOINT)
      @api_key = api_key
      @endpoint = endpoint
    end

    def send_email(from:, to:, subject:, text_body:, reply_to: nil)
      response = Net::HTTP.start(@endpoint.host, @endpoint.port, use_ssl: @endpoint.scheme == "https") do |http|
        http.request(request(from:, to:, subject:, text_body:, reply_to:))
      end

      return response if response.is_a?(Net::HTTPSuccess)

      raise Error, "Postmark delivery failed: #{response.code} #{response.body}"
    end

    private

    def request(from:, to:, subject:, text_body:, reply_to:)
      request = Net::HTTP::Post.new(@endpoint)
      request["Accept"] = "application/json"
      request["Content-Type"] = "application/json"
      request["X-Postmark-Server-Token"] = @api_key.to_s
      request.body = payload(from:, to:, subject:, text_body:, reply_to:).to_json
      request
    end

    def payload(from:, to:, subject:, text_body:, reply_to:)
      {
        From: from,
        To: to,
        Subject: subject,
        TextBody: text_body
      }.tap do |attributes|
        attributes[:ReplyTo] = reply_to if reply_to.present?
      end
    end
  end
end
