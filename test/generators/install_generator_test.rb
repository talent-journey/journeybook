require "test_helper"
require "rails/generators/test_case"
require "generators/journeybook/install/install_generator"

module Journeybook
  module Generators
    class InstallGeneratorTest < Rails::Generators::TestCase
      tests InstallGenerator
      destination File.expand_path("../tmp/generators", __dir__)
      setup :prepare_destination

      test "creates initializer directories and migrations" do
        run_generator

        assert_file "config/initializers/journeybook.rb"
        assert_file "config/initializers/journeybook.rb" do |initializer|
          assert_includes initializer, "journeybook_credentials = Rails.application.credentials.fetch(:journeybook, {})"
          assert_includes initializer, "journeybook_s3_default = journeybook_credentials.dig(:s3, :default) || {}"
          assert_includes initializer, "journeybook_s3_env = journeybook_credentials.dig(:s3, Rails.env.to_sym) || {}"
          assert_includes initializer, "journeybook_s3 = journeybook_s3_default.merge(journeybook_s3_env)"
          assert_includes initializer, "config.admin_basic_auth username: journeybook_credentials.dig(:admin, :username), password: journeybook_credentials.dig(:admin, :password)"
          assert_includes initializer, "config.openai_api_key = journeybook_credentials.dig(:openai, :api_key)"
          assert_includes initializer, "config.openai_model = journeybook_credentials.dig(:openai, :model) || config.openai_model"
          assert_includes initializer, "config.postmark_api_key"
          assert_includes initializer, "journeybook_credentials.dig(:postmark, :api_key)"
          assert_includes initializer, "config.form_from"
          assert_includes initializer, "config.form_to"
          assert_includes initializer, "config.form_action"
          assert_includes initializer, "config.form_delivery_method"
          assert_includes initializer, "config.s3_bucket = journeybook_s3[:bucket]"
          assert_includes initializer, "config.s3_region = journeybook_s3[:region]"
          assert_includes initializer, "config.s3_access_key_id = journeybook_s3[:access_key_id]"
          assert_includes initializer, "config.s3_secret_access_key = journeybook_s3[:secret_access_key]"
          assert_includes initializer, "config.s3_prefix = journeybook_s3[:prefix]"
          assert_includes initializer, '"journeybook/#{Rails.env}"'
          assert_includes initializer, "config.s3_public_base_url = journeybook_s3[:public_base_url]"
        end
        assert_file "app/controllers/pages_controller.rb"
        assert_file "app/views/pages/show.html.erb"
        assert_file "app/components/.keep"
        assert_file "app/components/previews/.keep"
        assert_file "test/components/previews/.keep"
        engine_migrations = Dir[Journeybook::Engine.root.join("db/migrate/*.rb")].map do |migration|
          File.basename(migration).sub(/\A\d+_/, "")
        end
        assert_equal engine_migrations.sort, InstallGenerator::MIGRATION_TEMPLATES.sort

        InstallGenerator::MIGRATION_TEMPLATES.each do |migration|
          assert_equal 1, Dir[File.join(destination_root, "db/migrate/*_#{migration}")].length
        end

        assert_file "config/routes.rb" do |routes|
          assert_includes routes, 'mount Journeybook::Engine => "/journeybook"'
          assert_includes routes, 'root "pages#show"'
          assert_includes routes, "constraints Journeybook::PublicPageConstraint.new do"
          assert_includes routes, 'get "*path" => "pages#show", as: :journeybook_page'
        end
      end
    end
  end
end
