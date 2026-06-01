# frozen_string_literal: true

RSpec.describe ViewComponent::ScopedStyles do
  it "has a version number" do
    expect(ViewComponent::ScopedStyles::VERSION).not_to be nil
  end

  describe "Configuration" do
    it "defaults components_path, assets_path, and stylesheet_name" do
      config = ViewComponent::ScopedStyles::Configuration.new

      expect(config.components_path).to eq(File.join("app", "components"))
      expect(config.assets_path).to eq(File.join("app", "assets", "stylesheets"))
      expect(config.stylesheet_name).to eq("components.scoped.css")
    end

    it "defaults css_class_prefix to {class_name}_" do
      config = ViewComponent::ScopedStyles::Configuration.new

      expect(config.css_class_prefix).to eq("{class_name}_")
    end
  end

  describe "css_class_prefix" do
    after do
      ViewComponent::ScopedStyles.configuration.css_class_prefix = "{class_name}_"
    end

    let(:component_class) do
      Class.new do
        def self.name = "PrefixedComponent"

        include ViewComponent::ScopedStyles

        styles do
          <<~CSS
            .component {
              color: red;
            }
          CSS
        end
      end
    end

    it "uses the global configuration prefix by default" do
      ViewComponent::ScopedStyles.configuration.css_class_prefix = "vc-"
      css = component_class.component_styles

      expect(css).to match(/\.vc-[0-9a-f]{8}\s*\{[^}]*color: red/)
    end

    it "interpolates {class_name} in the default prefix" do
      css = component_class.component_styles

      expect(css).to match(/\.component_[0-9a-f]{8}\s*\{[^}]*color: red/)
    end

    it "interpolates {component_name} and escapes / in compiled CSS" do
      ViewComponent::ScopedStyles.configuration.css_class_prefix = "{component_name}_{class_name}_"

      namespaced_component = Class.new do
        def self.name = "Admin::UserCardComponent"

        include ViewComponent::ScopedStyles

        styles do
          <<~CSS
            .component {
              color: red;
            }
          CSS
        end
      end

      css = namespaced_component.component_styles
      instance = namespaced_component.new

      expect(css).to match(/\.Admin\\\/UserCard_component_[0-9a-f]{8}\s*\{[^}]*color: red/)
      expect(instance.component_class).to match(/\AAdmin\/UserCard_component_[0-9a-f]{8}\z/)
    end

    it "strips the Component suffix from {component_name}" do
      ViewComponent::ScopedStyles.configuration.css_class_prefix = "{component_name}_{class_name}_"

      cool_button = Class.new do
        def self.name = "CoolButtonComponent"

        include ViewComponent::ScopedStyles

        styles do
          <<~CSS
            .component {
              color: blue;
            }
          CSS
        end
      end

      cool_button.component_styles
      instance = cool_button.new

      expect(instance.component_class).to match(/\ACoolButton_component_[0-9a-f]{8}\z/)
    end

    it "uses a per-component prefix when css_class_prefix is set" do
      prefixed_component = Class.new do
        def self.name = "PrefixedComponent"

        include ViewComponent::ScopedStyles

        css_class_prefix "my-"

        styles do
          <<~CSS
            .component {
              color: red;
            }
          CSS
        end
      end

      css = prefixed_component.component_styles

      expect(css).to match(/\.my-[0-9a-f]{8}\s*\{[^}]*color: red/)
    end

    it "returns scoped names with the configured prefix from component_class" do
      ViewComponent::ScopedStyles.configuration.css_class_prefix = "vc-"
      component_class.component_styles
      instance = component_class.new

      expect(instance.component_class).to match(/\Avc-[0-9a-f]{8}\z/)
    end
  end

  describe "ignored_css_classes" do
    let(:component_class) do
      Class.new do
        def self.name = "IgnoredClassesComponent"

        include ViewComponent::ScopedStyles

        ignored_css_classes "global", ".utility"

        styles do
          <<~CSS
            .component {
              color: red;
            }

            .global {
              font-size: 12px;
            }

            .utility {
              padding: 0;
            }

            .scoped {
              margin: 0;
            }
          CSS
        end
      end
    end

    it "leaves ignored selectors unchanged in generated CSS" do
      css = component_class.component_styles

      expect(css).to include(".global {")
      expect(css).to include(".utility {")
      expect(css).not_to match(/\.c-[0-9a-f]{8}\s*\{[^}]*font-size/)
    end

    it "still scopes non-ignored selectors" do
      css = component_class.component_styles

      expect(css).to match(/\.component_[0-9a-f]{8}\s*\{[^}]*color: red/)
      expect(css).to match(/\.scoped_[0-9a-f]{8}\s*\{[^}]*margin: 0/)
    end

    it "returns original names from component_class for ignored selectors" do
      component_class.component_styles
      instance = component_class.new

      expect(instance.component_class("global")).to eq("global")
      expect(instance.component_class("utility")).to eq("utility")
    end

    it "returns scoped names from component_class for other selectors" do
      component_class.component_styles
      instance = component_class.new

      expect(instance.component_class("scoped")).to match(/\Ascoped_[0-9a-f]{8}\z/)
    end
  end
end
