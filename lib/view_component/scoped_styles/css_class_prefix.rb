# frozen_string_literal: true

module ViewComponent
  module ScopedStyles
    # Interpolates +css_class_prefix+ template variables and escapes scoped class
    # names for use in compiled CSS selectors.
    class CssClassPrefix
      VARIABLES = %w[component_name class_name].freeze
      VARIABLE_PATTERN = /\{(#{VARIABLES.join("|")})\}/

      class << self
        # Replaces +{component_name}+ and +{class_name}+ in +template+.
        #
        # @param template [String] prefix template (e.g. +"{class_name}_"+)
        # @param component_name [String] component name with namespaces joined by +/+,
        #   and a trailing +Component+ suffix removed
        # @param class_name [String] CSS class being scoped
        # @return [String]
        def interpolate(template, component_name:, class_name:)
          template.gsub(VARIABLE_PATTERN) do
            case ::Regexp.last_match(1)
            when "component_name" then component_name
            when "class_name" then class_name
            end
          end
        end

        # Escapes characters that are invalid in unescaped CSS class selectors.
        #
        # @param class_name [String]
        # @return [String]
        def escape_for_css_selector(class_name)
          class_name.gsub("/", '\/')
        end
      end
    end
  end
end
