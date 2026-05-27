# frozen_string_literal: true

require "fileutils"
require "tmpdir"
require "rspec"
require "view_component/scoped_styles/configuration"
require "generators/view_component/scoped_styles/install_generator"

RSpec.describe ViewComponent::ScopedStyles::Generators::InstallGenerator do
  let(:destination_root) { Pathname(Dir.mktmpdir) }

  after { FileUtils.rm_rf(destination_root) }

  def run_install_generator
    generator = described_class.new([], {}, destination_root: destination_root.to_s)
    generator.invoke_all
  end

  def initializer_path
    destination_root.join("config/initializers/view_component_scoped_styles.rb")
  end

  it "creates an initializer with configuration defaults" do
    run_install_generator

    expect(initializer_path).to exist

    content = initializer_path.read
    defaults = ViewComponent::ScopedStyles::Configuration.new

    expect(content).to include(
      %(config.components_path = File.join("app", "components"))
    )
    expect(content).to include("config.components_layer = #{defaults.components_layer.inspect}")
  end
end
