# frozen_string_literal: true

require "active_support/core_ext/module/delegation"
require "rails/railtie"

module ViewComponent
  module ScopedStyles
    class Railtie < Rails::Railtie
      config.after_initialize do
        ViewComponent::ScopedStyles::Railtie.load_and_register_components
      end

      initializer "view_component.scoped_styles.reload" do |app|
        next unless Rails.env.development?

        app.config.to_prepare do
          ViewComponent::ScopedStyles::Railtie.register_components
        end
      end

      class << self
        def component_path
          Rails.root.join("app/components/**/*.rb")
        end

        def load_and_register_components
          Dir[component_path].each { require_dependency _1 }

          register_components
        end

        def register_components
          ObjectSpace
            .each_object(Class)
            .select { _1.ancestors.include?(ViewComponent::ScopedStyles) }
            .each(&:register_styles)
        end
      end
    end
  end
end
