require "journeybook/version"
require "journeybook/component_registry"
require "journeybook/page_template_registry"
require "journeybook/configuration"
require "journeybook/public_page_constraint"
require "journeybook/engine"

module Journeybook
  class Error < StandardError; end
  class UnknownComponentError < Error; end

  class << self
    # @return [Journeybook::Configuration]
    def configuration
      @configuration ||= Configuration.new
    end

    # @yieldparam config [Journeybook::Configuration]
    # @return [Journeybook::Configuration]
    def configure
      yield configuration
      configuration
    end

    # @return [Journeybook::ComponentRegistry]
    def components
      configuration.components
    end

    # @param name [String, Symbol]
    # @return [Object]
    def component(name)
      components.fetch(name)
    end

    # @param name [String, Symbol]
    # @param component_class [Class]
    # @param metadata [Hash]
    # @return [Object]
    def register(name, component_class, **metadata)
      components.register(name, component_class, **metadata)
    end

    # @return [Journeybook::PageTemplateRegistry]
    def templates
      configuration.templates
    end

    # @param key [String, Symbol]
    # @return [Journeybook::PageTemplateRegistry::Template]
    def template(key)
      templates.fetch(key)
    end

    # @param key [String, Symbol]
    # @param metadata [Hash]
    # @return [Journeybook::PageTemplateRegistry::Template]
    def register_template(key, **metadata)
      templates.register(key, **metadata)
    end
  end
end
