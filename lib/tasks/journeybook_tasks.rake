namespace :journeybook do
  desc "Install Journeybook migrations, initializer, and host component directories"
  task install: :environment do
    require "rails/generators"

    Rails::Generators.invoke("journeybook:install", [], destination_root: Rails.root)
  end
end
