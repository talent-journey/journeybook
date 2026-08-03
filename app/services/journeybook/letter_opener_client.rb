module Journeybook
  class LetterOpenerClient
    def send_email(from:, to:, subject:, text_body:, reply_to: nil)
      require "letter_opener"

      message = Mail.new(from:, to:, subject:, body: text_body)
      message.reply_to = reply_to if reply_to.present?
      message.delivery_method(LetterOpener::DeliveryMethod, location: Rails.root.join("tmp/letter_opener"))
      message.deliver!
    rescue LoadError
      raise FormMailer::ConfigurationError, "Install the letter_opener gem to use Journeybook form_delivery_method = :letter_opener"
    end
  end
end
