module Journeybook
  class FormSubmissionsController < ActionController::Base
    protect_from_forgery with: :exception

    FORM_FIELDS = %w[firstname lastname name email phone company contact_subject message privacy subject].freeze
    MAX_REQUEST_BYTES = 20.kilobytes
    MAX_FIELD_LENGTH = 5_000

    rate_limit to: 5, within: 1.minute, by: -> { request.remote_ip }, only: :create, with: -> {
      redirect_to redirect_location, alert: "Please wait before sending another message."
    }

    def create
      return redirect_to redirect_location, notice: confirmation_text if honeypot_triggered?

      validate_submission!
      FormMailer.new.deliver(fields: form_fields)
      redirect_to redirect_location, notice: confirmation_text
    rescue SubmissionError, FormMailer::ConfigurationError, PostmarkClient::Error => error
      redirect_to redirect_location, alert: error.message
    end

    private

    class SubmissionError < StandardError; end

    def form_fields
      params.permit(*FORM_FIELDS).to_h.transform_values { |value| value.to_s.strip }
    end

    def validate_submission!
      raise SubmissionError, "The form submission is too large." if request.content_length.to_i > MAX_REQUEST_BYTES

      fields = form_fields
      raise SubmissionError, "Please provide a valid email address." unless fields["email"].match?(URI::MailTo::EMAIL_REGEXP)
      raise SubmissionError, "Please enter a message." if params.key?(:message) && fields["message"].blank?
      raise SubmissionError, "The form submission contains a field that is too long." if fields.values.any? { |value| value.length > MAX_FIELD_LENGTH }
    end

    def honeypot_triggered?
      params[:website].present?
    end

    def redirect_location
      return_to = params[:return_to].to_s
      return return_to if return_to.start_with?("/") && !return_to.start_with?("//")

      request.referer.presence || "/"
    end

    def confirmation_text
      params[:confirmation_text].to_s.strip.presence || "Thanks, your message was sent."
    end
  end
end
