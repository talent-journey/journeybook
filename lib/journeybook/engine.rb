require "importmap-rails"
require "stimulus-rails"

module Journeybook
  class Engine < ::Rails::Engine
    isolate_namespace Journeybook

    config.autoload_paths << root.join("app/services")
    config.eager_load_paths << root.join("app/services")

    initializer "journeybook.importmap", after: "importmap" do |app|
      path = root.join("config/importmap.rb")
      app.config.importmap.paths << path
      app.config.importmap.cache_sweepers << root.join("app/javascript")
      app.config.assets.paths << root.join("app/javascript")
      app.importmap.draw(path)
    end
  end
end
