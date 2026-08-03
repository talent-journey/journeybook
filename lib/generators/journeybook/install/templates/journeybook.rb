journeybook_credentials = Rails.application.credentials.fetch(:journeybook, {})
journeybook_s3_default = journeybook_credentials.dig(:s3, :default) || {}
journeybook_s3_env = journeybook_credentials.dig(:s3, Rails.env.to_sym) || {}
journeybook_s3 = journeybook_s3_default.merge(journeybook_s3_env)

Journeybook.configure do |config|
  config.default_layout = "application"

  # Journeybook denies admin access until the host application configures it.
  # config.admin_basic_auth username: journeybook_credentials.dig(:admin, :username), password: journeybook_credentials.dig(:admin, :password)

  config.openai_api_key = journeybook_credentials.dig(:openai, :api_key)
  config.openai_model = journeybook_credentials.dig(:openai, :model) || config.openai_model

  # Required when using Journeybook form components that send email via Postmark.
  config.postmark_api_key = journeybook_credentials.dig(:postmark, :api_key)
  # config.form_from = "noreply@example.com"
  # config.form_to = "team@example.com"
  # config.form_action = "/journeybook/form"
  # config.form_delivery_method = Rails.env.development? ? :letter_opener : :postmark

  # Required when using the Journeybook image library.
  config.s3_bucket = journeybook_s3[:bucket]
  config.s3_region = journeybook_s3[:region]
  config.s3_access_key_id = journeybook_s3[:access_key_id]
  config.s3_secret_access_key = journeybook_s3[:secret_access_key]
  config.s3_prefix = journeybook_s3[:prefix] || "journeybook/#{Rails.env}"
  # Optional: use CloudFront, a CDN, or another custom public host instead of the default S3 URL.
  config.s3_public_base_url = journeybook_s3[:public_base_url]
end

# Register host application components here. `to_prepare` keeps registrations
# compatible with development reloading and eager loading.
# Rails.application.config.to_prepare do
#   Journeybook.register :hero, Website::HeroComponent,
#                        description: "Large hero section",
#                        props: {
#                          title: "Main headline",
#                          body: { type: :long_text, description: "Supporting copy" },
#                          image_url: { type: :image, label: "Image", description: "Image from the Journeybook library" }
#                        }
# end
