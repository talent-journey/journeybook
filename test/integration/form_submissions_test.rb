require "test_helper"

class FormSubmissionsTest < ActionDispatch::IntegrationTest
  class FakeMailer
    attr_reader :fields

    def deliver(fields:)
      @fields = fields
    end
  end

  test "sends form submission and redirects back" do
    mailer = FakeMailer.new
    original_new = Journeybook::FormMailer.method(:new)
    Journeybook::FormMailer.define_singleton_method(:new) { mailer }

    post "/journeybook/form", params: {
      name: "Ada Lovelace",
      email: "ada@example.test",
      message: "Hello",
      unexpected: "ignored",
      return_to: "/#contact",
      authenticity_token: "ignored"
    }, headers: { "HTTP_REFERER" => "/contact" }

    assert_redirected_to "/#contact"
    assert_equal "Thanks, your message was sent.", flash[:notice]
    assert_equal "Ada Lovelace", mailer.fields["name"]
    assert_equal "ada@example.test", mailer.fields["email"]
    assert_equal "Hello", mailer.fields["message"]
    refute_includes mailer.fields, "unexpected"
    refute_includes mailer.fields, "authenticity_token"
    refute_includes mailer.fields, "return_to"
  ensure
    Journeybook::FormMailer.define_singleton_method(:new, original_new)
  end

  test "does not deliver honeypot submissions" do
    mailer = FakeMailer.new
    original_new = Journeybook::FormMailer.method(:new)
    Journeybook::FormMailer.define_singleton_method(:new) { mailer }

    post "/journeybook/form", params: { email: "ada@example.test", message: "Hello", website: "bot" }

    assert_redirected_to "/"
    assert_nil mailer.fields
  ensure
    Journeybook::FormMailer.define_singleton_method(:new, original_new)
  end

  test "accepts submissions without a message and uses the confirmation text" do
    mailer = FakeMailer.new
    original_new = Journeybook::FormMailer.method(:new)
    Journeybook::FormMailer.define_singleton_method(:new) { mailer }

    post "/journeybook/form", params: { email: "ada@example.test", company: "Analytical Engines", confirmation_text: "Danke, wir melden uns." }

    assert_redirected_to "/"
    assert_equal "Danke, wir melden uns.", flash[:notice]
    assert_equal "Analytical Engines", mailer.fields["company"]
  ensure
    Journeybook::FormMailer.define_singleton_method(:new, original_new)
  end

  test "rejects invalid form submissions" do
    post "/journeybook/form", params: { email: "invalid", message: "" }

    assert_redirected_to "/"
    assert_equal "Please provide a valid email address.", flash[:alert]
  end
end
