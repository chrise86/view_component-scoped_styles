# frozen_string_literal: true

module ViewComponent
  module ScopedStyles
    # Global settings for ViewComponent::ScopedStyles.
    #
    # Configure in an initializer:
    #
    #   ViewComponent::ScopedStyles.configure do |config|
    #     config.components_path = File.join("app", "view_components")
    #     config.components_layer = "components"
    #   end
    class Configuration
      # Directory where ViewComponent classes live, relative to {Rails.root}.
      #
      # @return [String] default: +"app/components"+
      attr_accessor :components_path

      # Optional CSS cascade layer name for generated styles in
      # +app/assets/stylesheets/components.scoped.css+.
      #
      # When set, the bundled stylesheet is wrapped in +@layer <name> { ... }+ so
      # you can control specificity relative to other layers in your app.
      #
      # @return [String, nil] default: +nil+ (no layer wrapper)
      attr_accessor :components_layer

      def initialize
        @components_path = File.join("app", "components")
        @components_layer = nil
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
