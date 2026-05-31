# frozen_string_literal: true

module ViewComponent
  module ScopedStyles
    # Global settings for ViewComponent::ScopedStyles.
    #
    # Configure in an initializer:
    #
    #   ViewComponent::ScopedStyles.configure do |config|
    #     config.components_path = File.join("app", "view_components")
    #     config.assets_path = File.join("app", "assets", "stylesheets")
    #     config.stylesheet_name = "components.scoped.css"
    #     config.components_layer = "components"
    #   end
    class Configuration
      # Directory where ViewComponent classes live, relative to {Rails.root}.
      #
      # @return [String] default: +"app/components"+
      attr_accessor :components_path

      # Directory where the bundled scoped stylesheet is written, relative to {Rails.root}.
      #
      # @return [String] default: +"app/assets/stylesheets"+
      attr_accessor :assets_path

      # Filename of the bundled scoped stylesheet within {assets_path}.
      #
      # @return [String] default: +"components.scoped.css"+
      attr_accessor :stylesheet_name

      # Optional CSS cascade layer name for the bundled scoped stylesheet.
      #
      # When set, the bundled stylesheet is wrapped in +@layer <name> { ... }+ so
      # you can control specificity relative to other layers in your app.
      #
      # @return [String, nil] default: +nil+ (no layer wrapper)
      attr_accessor :components_layer

      # Prefix prepended to scoped class names (e.g. +"c-"+ → +"c-a1b2c3d4"+).
      #
      # @return [String] default: +"c-"+
      attr_accessor :css_class_prefix

      def initialize
        @components_path = File.join("app", "components")
        @assets_path = File.join("app", "assets", "stylesheets")
        @stylesheet_name = "components.scoped.css"
        @components_layer = nil
        @css_class_prefix = "c-"
      end
    end

    class << self
      # Returns the global configuration object, creating it on first access.
      #
      # @return [Configuration]
      def configuration
        @configuration ||= Configuration.new
      end

      # Yields the global configuration for block-style setup.
      #
      # @yieldparam config [Configuration]
      # @return [void]
      def configure = yield(configuration)
    end
  end
end
