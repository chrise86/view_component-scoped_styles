# frozen_string_literal: true

require "rspec"
require "open3"
require "rails/generators"
require "view_component"
require "view_component/scoped_styles/component_generator_hook"
require "generators/view_component/component/component_generator"

RSpec.describe ViewComponent::Generators::ComponentGenerator do
  it "adds a stylesheet class option enabled by default" do
    expect(described_class.class_options[:stylesheet]).to be_present
    expect(described_class.class_options[:stylesheet].default).to be(true)
  end

  [
    ["component default", "g.component stylesheet: true", [], true],
    ["namespace fallback", "g.view_component stylesheet: true", [], true],
    ["unconfigured default", "", [], true],
    ["configured disable", "g.component stylesheet: false", [], false],
    ["explicit disable", "g.component stylesheet: true", ["--no-stylesheet"], false],
    ["explicit enable", "g.component stylesheet: false", ["--stylesheet"], true],
    ["false precedence", "g.view_component stylesheet: true; g.component stylesheet: false", [], false]
  ].each do |description, configuration, flags, expected|
    it "generates the expected files for #{description}" do
      script = <<~RUBY
        require "bundler/setup"
        require "rails"
        require "rails/application"
        require "view_component"
        require "view_component/scoped_styles"
        require "tmpdir"
        generate = ViewComponent::Base.config.generate
        def generate.stylesheet
          raise "Unknown ViewComponent configuration option: stylesheet"
        end
        class GeneratorTestApp < Rails::Application
          config.eager_load = false
          config.logger = Logger.new(nil)
          config.generators do |g|
            g.template_engine :erb
            g.test_framework false
            #{configuration}
          end
        end
        app = GeneratorTestApp.instance
        Dir.mktmpdir do |destination|
          app.config.root = destination
          app.initialize!
          app.load_generators
          Rails::Generators.invoke("view_component:component", ["Example", *#{flags.inspect}],
            destination_root: destination)
          css = File.exist?(File.join(destination, "app/components/example_component.css"))
          abort "Unexpected stylesheet presence: " + css.inspect unless css == #{expected}
          if css
            component = File.read(File.join(destination, "app/components/example_component.rb"))
            abort "Missing scoped styles include" unless component.include?("include ViewComponent::ScopedStyles")
          end
        end
      RUBY

      output, status = Open3.capture2e(Gem.ruby, "-e", script)

      expect(status).to be_success, output
    end
  end

  it "registers a stylesheet generator hook" do
    hook_names = described_class.hooks.map { |hook| hook.is_a?(Array) ? hook.first : hook.name }
    expect(hook_names).to include(:stylesheet)
  end
end
