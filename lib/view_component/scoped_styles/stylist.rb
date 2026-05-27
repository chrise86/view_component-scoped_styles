# frozen_string_literal: true

require "view_component/scoped_styles/stylist/writer"

module ViewComponent
  module ScopedStyles
    class Stylist
      def self.register(component_class)
        return if unstyled?(component_class)

        Writer.print(component_class)
      end

      private_class_method def self.unstyled?(component_class)
        !component_class.component_styles &&
          !component_class.instance_variable_get(:@component_id)
      end
    end
  end
end
