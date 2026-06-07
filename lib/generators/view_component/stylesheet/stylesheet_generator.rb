# frozen_string_literal: true

require "rails/generators"
require "generators/view_component/abstract_generator"

module ViewComponent
  module Generators
    class StylesheetGenerator < ::Rails::Generators::NamedBase
      include ViewComponent::AbstractGenerator

      source_root File.expand_path("templates", __dir__)
      class_option :sidecar, type: :boolean, default: false
      class_option :skip_suffix, type: :boolean, default: false

      def create_stylesheet
        template "component.css", stylesheet_destination
      end

      def inject_scoped_styles_module
        return unless File.exist?(absolute_component_rb_path)

        content = File.read(absolute_component_rb_path)
        return if content.include?("ViewComponent::ScopedStyles")

        class_name_pattern = component_class_name.split("::").last
        match = content.match(/^(\s*)class #{Regexp.escape(class_name_pattern)}\b[^\n]*\n/)
        return unless match

        indent = "#{match[1]}  "
        inject_into_file component_rb_path,
          "#{indent}include ViewComponent::ScopedStyles\n",
          after: match[0]
      end

      def update_view_template
        return if options["inline"] || options["call"]

        path = view_template_path
        return unless File.exist?(File.join(destination_root, path))

        gsub_file path, /<div/, '<div class="<%= component_class %>"', verbose: false
      end

      private

      def absolute_component_rb_path
        File.join(destination_root, component_rb_path)
      end

      def component_file_name
        "#{file_name}#{"_component" unless options[:skip_suffix]}"
      end

      def component_class_name
        "#{class_name}#{"Component" unless options[:skip_suffix]}"
      end

      def component_rb_path
        File.join(component_path, class_path, "#{component_file_name}.rb")
      end

      def stylesheet_destination
        if sidecar?
          File.join(
            component_path, class_path, component_file_name, "#{component_file_name}.css"
          )
        else
          File.join(component_path, class_path, "#{component_file_name}.css")
        end
      end

      def view_template_path
        File.join(destination_directory, "#{destination_file_name}.html.erb")
      end
    end
  end
end
