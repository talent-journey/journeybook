module Journeybook
  class FormMailer
    class ConfigurationError < StandardError; end

    DEFAULT_SUBJECT = "New Journeybook form submission".freeze

    def initialize(client: nil, configuration: Journeybook.configuration)
      @client = client
      @configuration = configuration
    end

    def deliver(fields:)
      validate_configuration!

      client.send_email(
        from: @configuration.form_from,
        to: @configuration.form_to,
        subject: fields.delete("subject").to_s.truncate(200).presence || DEFAULT_SUBJECT,
        text_body: body_for(fields),
        reply_to: reply_to_for(fields)
      )
    end

    private

    def client
      @client ||= delivery_client
    end

    def delivery_client
      case delivery_method
      when "postmark"
        PostmarkClient.new(api_key: @configuration.postmark_api_key)
      when "letter_opener"
        LetterOpenerClient.new
      else
        raise ConfigurationError, "Unsupported Journeybook form delivery method: #{delivery_method}"
      end
    end

    def delivery_method
      @configuration.form_delivery_method.to_s
    end

    def validate_configuration!
      missing = []
      missing << "postmark_api_key" if delivery_method == "postmark" && @configuration.postmark_api_key.blank?
      missing << "form_from" if @configuration.form_from.blank?
      missing << "form_to" if @configuration.form_to.blank?
      return if missing.empty?

      raise ConfigurationError, "Missing Journeybook email configuration: #{missing.join(", ")}"
    end

    def body_for(fields)
      fields.map do |name, value|
        "#{name.to_s.humanize}: #{format_value(value)}"
      end.join("\n\n")
    end

    def format_value(value)
      Array(value).join(", ")
    end

    def reply_to_for(fields)
      fields["email"].presence
    end
  end
end
