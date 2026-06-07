# frozen_string_literal: true

require "rspec"
require "rails/generators"
require "view_component"
require "view_component/scoped_styles/component_generator_hook"
require "generators/view_component/component/component_generator"

RSpec.describe ViewComponent::Generators::ComponentGenerator do
  it "adds a stylesheet class option defaulting to ViewComponent generate config" do
    expect(described_class.class_options[:stylesheet]).to be_present
    expect(described_class.class_options[:stylesheet].default).to be(false)
  end

  it "registers a stylesheet generator hook" do
    hook_names = described_class.hooks.map { |hook| hook.is_a?(Array) ? hook.first : hook.name }
    expect(hook_names).to include(:stylesheet)
  end
end
