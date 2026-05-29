# frozen_string_literal: true

RSpec.describe ViewComponent::ScopedStyles do
  it "has a version number" do
    expect(ViewComponent::ScopedStyles::VERSION).not_to be nil
  end

  describe "css_class_prefix" do
    after do
      ViewComponent::ScopedStyles.configuration.css_class_prefix = "c-"
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

      expect(css).to match(/\.c-[0-9a-f]{8}\s*\{[^}]*color: red/)
      expect(css).to match(/\.c-[0-9a-f]{8}\s*\{[^}]*margin: 0/)
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

      expect(instance.component_class("scoped")).to match(/\Ac-[0-9a-f]{8}\z/)
    end
  end
end
