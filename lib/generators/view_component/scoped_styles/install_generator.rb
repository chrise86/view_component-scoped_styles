# frozen_string_literal: true

require "view_component/scoped_styles/configuration"
require "rails/generators"

module ViewComponent
  module ScopedStyles
    module Generators
      # Installs +config/initializers/view_component_scoped_styles.rb+ with defaults
      # from {ViewComponent::ScopedStyles::Configuration}.
      #
      #   bin/rails generate view_component:scoped_styles:install
      class InstallGenerator < Rails::Generators::Base
        source_root File.expand_path("templates", __dir__)

        desc "Creates a ViewComponent::ScopedStyles initializer with default configuration"

        def copy_initializer
          template "view_component_scoped_styles.rb.tt",
            "config/initializers/view_component_scoped_styles.rb"
        end

        private

        def configuration_defaults
          @configuration_defaults ||= Configuration.new
        end

        def components_path_expression
          path_expression_for(configuration_defaults.components_path)
        end

        def assets_path_expression
          path_expression_for(configuration_defaults.assets_path)
        end

        def stylesheet_name_value
          configuration_defaults.stylesheet_name.inspect
        end

        def components_layer_value
          configuration_defaults.components_layer.inspect
        end

        def css_class_prefix_value
          configuration_defaults.css_class_prefix.inspect
        end

        def path_expression_for(path)
          segments = Pathname(path).each_filename.to_a
          "File.join(#{segments.map { |segment| %("#{segment}") }.join(", ")})"
        end
      end
    end
  end
end
