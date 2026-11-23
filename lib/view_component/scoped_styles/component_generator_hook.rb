# frozen_string_literal: true

require "rails/generators"
require "generators/view_component/component/component_generator"

module ViewComponent
  module Generators
    class ComponentGenerator
      class_option :stylesheet, type: :boolean, default: false

      hook_for :stylesheet, type: :boolean
    end
  end
end
