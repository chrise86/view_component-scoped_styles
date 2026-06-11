# frozen_string_literal: true

require "open3"

RSpec.describe ViewComponent::ScopedStyles::Railtie do
  it "does not load component generators when the gem is required" do
    script = <<~RUBY
      require "bundler/setup"
      require "view_component/scoped_styles"
      print $LOADED_FEATURES.grep(/component_generator/).join("\\n")
    RUBY

    output, status = Open3.capture2(Gem.ruby, "-e", script)

    expect(status).to be_success
    expect(output).to be_empty
  end

  describe ".component_path" do
    let(:rails_root) { Pathname.new("/tmp/myapp") }

    before do
      allow(Rails).to receive(:root).and_return(rails_root)
    end

    after do
      ViewComponent::ScopedStyles.configuration.components_path =
        File.join("app", "components")
    end

    it "uses the configured components_path" do
      ViewComponent::ScopedStyles.configuration.components_path =
        File.join("app", "view_components")

      expect(described_class.component_path.to_s).to eq(
        "/tmp/myapp/app/view_components/**/*.rb"
      )
    end

    it "defaults to app/components" do
      expect(described_class.component_path.to_s).to eq(
        "/tmp/myapp/app/components/**/*.rb"
      )
    end
  end
end
