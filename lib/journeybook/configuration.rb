module Journeybook
  class Configuration
    attr_accessor :default_layout, :admin_authenticator, :ai_provider, :openai_api_key, :openai_model,
      :postmark_api_key, :form_from, :form_to, :form_action, :form_delivery_method,
      :s3_bucket, :s3_region, :s3_access_key_id, :s3_secret_access_key, :s3_prefix, :s3_public_base_url
    attr_reader :components, :templates

    def initialize
      @default_layout = "application"
      @admin_authenticator = ->(_controller) { false }
      @ai_provider = :openai
      @openai_api_key = nil
      @openai_model = "gpt-5.4-mini"
      @postmark_api_key = nil
      @form_from = nil
      @form_to = nil
      @form_action = "/journeybook/form"
      @form_delivery_method = :postmark
      @s3_bucket = nil
      @s3_region = nil
      @s3_access_key_id = nil
      @s3_secret_access_key = nil
      @s3_prefix = "journeybook/#{Rails.env}"
      @s3_public_base_url = nil
      @components = ComponentRegistry.new
      @templates = PageTemplateRegistry.new
    end

    # @param name [String, Symbol]
    # @param component_class [Class]
    # @param metadata [Hash]
    # @return [Object]
    def component(name, component_class, **metadata)
      components.register(name, component_class, **metadata)
    end

    def admin_basic_auth(username:, password:, realm: "Journeybook")
      @admin_authenticator = lambda do |controller|
        expected_username = username.to_s
        expected_password = password.to_s

        controller.authenticate_or_request_with_http_basic(realm) do |provided_username, provided_password|
          expected_username.present? && expected_password.present? &&
            secure_compare(provided_username, expected_username) && secure_compare(provided_password, expected_password)
        end
      end
    end

    private

    def secure_compare(provided, expected)
      ActiveSupport::SecurityUtils.secure_compare(Digest::SHA256.hexdigest(provided), Digest::SHA256.hexdigest(expected))
    end
  end
end
