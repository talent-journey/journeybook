require "rails/generators"
require "rails/generators/active_record/migration"

module Journeybook
  module Generators
    class InstallGenerator < Rails::Generators::Base
      include ActiveRecord::Generators::Migration

      MIGRATION_TEMPLATES = %w[
        create_journeybook_sites.rb
        create_journeybook_pages.rb
        create_journeybook_redirects.rb
        add_context_fields_to_journeybook_sites.rb
        create_journeybook_media_assets.rb
        create_journeybook_navigation.rb
        add_open_in_new_window_to_journeybook_navigation_items.rb
        create_journeybook_ai_style_prompts.rb
        add_blog_fields_to_journeybook_pages.rb
        add_knowledge_base_fields_to_journeybook_pages.rb
        add_position_to_journeybook_pages.rb
      ].freeze

      source_root File.expand_path("templates", __dir__)

      def self.next_migration_number(dirname)
        @migration_number ||= Time.current.utc.strftime("%Y%m%d%H%M%S").to_i
        (@migration_number += 1).to_s
      end

      def copy_migrations
        MIGRATION_TEMPLATES.each do |migration|
          migration_template migration, "db/migrate/#{migration}"
        end
      end

      def copy_initializer
        template "journeybook.rb", "config/initializers/journeybook.rb"
      end

      def copy_public_page_files
        template "pages_controller.rb", "app/controllers/pages_controller.rb"
        copy_file "show.html.erb", "app/views/pages/show.html.erb"
      end

      def ensure_routes_file
        create_file "config/routes.rb", "Rails.application.routes.draw do\nend\n" unless File.exist?(File.join(destination_root, "config/routes.rb"))
      end

      def mount_admin_routes
        route 'mount Journeybook::Engine => "/journeybook"'
      end

      def add_public_routes
        route 'root "pages#show"'
        route <<~RUBY
          constraints Journeybook::PublicPageConstraint.new do
            get "*path" => "pages#show", as: :journeybook_page
          end
        RUBY
      end

      def create_component_directories
        empty_directory "app/components"
        empty_directory "app/components/previews"
        empty_directory "test/components/previews"
        create_file "app/components/.keep"
        create_file "app/components/previews/.keep"
        create_file "test/components/previews/.keep"
      end
    end
  end
end
