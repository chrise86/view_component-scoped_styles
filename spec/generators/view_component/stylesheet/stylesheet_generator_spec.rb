# frozen_string_literal: true

require "fileutils"
require "tmpdir"
require "rspec"
require "rails/generators"
require "view_component"
require "generators/view_component/stylesheet/stylesheet_generator"

RSpec.describe ViewComponent::Generators::StylesheetGenerator do
  let(:destination_root) { Pathname(Dir.mktmpdir) }
  let(:components_path) { destination_root.join("app/components") }

  before do
    FileUtils.mkdir_p(components_path)
    allow(ViewComponent::Base.config.generate).to receive(:path).and_return("app/components")
  end

  after { FileUtils.rm_rf(destination_root) }

  def write_component_class(content = <<~RUBY)
    # frozen_string_literal: true

    class ExampleComponent < ViewComponent::Base
    end
  RUBY
    File.write(components_path.join("example_component.rb"), content)
  end

  def write_view_template(content = '<div>Add Example template here</div>')
    File.write(components_path.join("example_component.html.erb"), content)
  end

  def run_stylesheet_generator(**options)
    generator = described_class.new(
      ["Example"],
      { sidecar: false }.merge(options),
      destination_root: destination_root.to_s
    )
    generator.invoke_all
  end

  it "creates a flat stylesheet next to the component" do
    run_stylesheet_generator

    stylesheet = components_path.join("example_component.css")
    expect(stylesheet).to exist
    expect(stylesheet.read).to include(".component {")
  end

  it "creates a sidecar stylesheet when --sidecar is passed" do
    run_stylesheet_generator(sidecar: true)

    stylesheet = components_path.join("example_component/example_component.css")
    expect(stylesheet).to exist
    expect(stylesheet.read).to include(".component {")
  end

  it "injects ViewComponent::ScopedStyles into the component class" do
    write_component_class
    run_stylesheet_generator

    component = components_path.join("example_component.rb").read
    expect(component).to include("include ViewComponent::ScopedStyles")
  end

  it "does not duplicate the include when it is already present" do
    write_component_class(<<~RUBY)
      # frozen_string_literal: true

      class ExampleComponent < ViewComponent::Base
        include ViewComponent::ScopedStyles
      end
    RUBY

    run_stylesheet_generator

    component = components_path.join("example_component.rb").read
    expect(component.scan("include ViewComponent::ScopedStyles").length).to eq(1)
  end

  it "adds component_class to the generated ERB template" do
    write_component_class
    write_view_template
    run_stylesheet_generator

    template = components_path.join("example_component.html.erb").read
    expect(template).to include('class="<%= component_class %>"')
  end
end
