# frozen_string_literal: true

require "rspec"
require "open3"
require "rails/generators"
require "view_component"
require "view_component/scoped_styles/component_generator_hook"
require "generators/view_component/component/component_generator"

RSpec.describe ViewComponent::Generators::ComponentGenerator do
  it "adds a stylesheet class option disabled by default" do
    expect(described_class.class_options[:stylesheet]).to be_present
    expect(described_class.class_options[:stylesheet].default).to be(false)
  end

  it "uses Rails generator configuration without reading a ViewComponent stylesheet option" do
    script = <<~RUBY
      require "bundler/setup"
      require "view_component/scoped_styles"
      require "rails/generators"
      require "view_component"
      generate = ViewComponent::Base.config.generate
      def generate.stylesheet
        raise "Unknown ViewComponent configuration option: stylesheet"
      end
      Rails::Generators.options[:view_component] = { stylesheet: true }
      require "view_component/scoped_styles/component_generator_hook"
      generator = ViewComponent::Generators::ComponentGenerator
      abort "stylesheet not enabled" unless generator.new(["Example"]).options[:stylesheet]
      abort "stylesheet not disabled" if generator.new(["Example"], stylesheet: false).options[:stylesheet]
    RUBY

    output, status = Open3.capture2e(Gem.ruby, "-e", script)

    expect(status).to be_success, output
  end

  it "registers a stylesheet generator hook" do
    hook_names = described_class.hooks.map { |hook| hook.is_a?(Array) ? hook.first : hook.name }
    expect(hook_names).to include(:stylesheet)
  end
end
