require "test_helper"

module Journeybook
  class FormMailerTest < ActiveSupport::TestCase
    FakeConfiguration = Data.define(:postmark_api_key, :form_from, :form_to, :form_delivery_method)

    class FakeClient
      attr_reader :delivery

      def send_email(**delivery)
        @delivery = delivery
      end
    end

    test "sends submitted fields through postmark client" do
      client = FakeClient.new
      configuration = FakeConfiguration.new("secret", "forms@example.test", "team@example.test", :postmark)

      FormMailer.new(client:, configuration:).deliver(fields: {
        "name" => "Ada Lovelace",
        "email" => "ada@example.test",
        "message" => "Hello",
        "subject" => "Contact form"
      })

      assert_equal "forms@example.test", client.delivery[:from]
      assert_equal "team@example.test", client.delivery[:to]
      assert_equal "Contact form", client.delivery[:subject]
      assert_equal "ada@example.test", client.delivery[:reply_to]
      assert_includes client.delivery[:text_body], "Name: Ada Lovelace"
      assert_includes client.delivery[:text_body], "Message: Hello"
    end

    test "requires email configuration" do
      error = assert_raises FormMailer::ConfigurationError do
        FormMailer.new(client: FakeClient.new, configuration: FakeConfiguration.new(nil, nil, nil, :postmark)).deliver(fields: {})
      end

      assert_includes error.message, "postmark_api_key"
      assert_includes error.message, "form_from"
      assert_includes error.message, "form_to"
    end

    test "does not require postmark api key for letter opener delivery" do
      client = FakeClient.new
      configuration = FakeConfiguration.new(nil, "forms@example.test", "team@example.test", :letter_opener)

      FormMailer.new(client:, configuration:).deliver(fields: { "message" => "Hello" })

      assert_equal "forms@example.test", client.delivery[:from]
      assert_equal "team@example.test", client.delivery[:to]
      assert_equal FormMailer::DEFAULT_SUBJECT, client.delivery[:subject]
    end

    test "rejects unsupported delivery methods" do
      error = assert_raises FormMailer::ConfigurationError do
        FormMailer.new(configuration: FakeConfiguration.new(nil, "forms@example.test", "team@example.test", :unknown)).deliver(fields: {})
      end

      assert_includes error.message, "Unsupported Journeybook form delivery method"
    end
  end
end
