# frozen_string_literal: true

RSpec.describe ViewComponent::ScopedStyles::CssClassPrefix do
  describe ".interpolate" do
    it "replaces {class_name}" do
      result = described_class.interpolate(
        "{class_name}_",
        component_name: "ExampleComponent",
        class_name: "component"
      )

      expect(result).to eq("component_")
    end

    it "replaces {component_name} with namespaces joined by /" do
      result = described_class.interpolate(
        "{component_name}/",
        component_name: "Admin/UserCard",
        class_name: "component"
      )

      expect(result).to eq("Admin/UserCard/")
    end

    it "replaces multiple variables" do
      result = described_class.interpolate(
        "{component_name}_{class_name}_",
        component_name: "Admin/UserCard",
        class_name: "inner"
      )

      expect(result).to eq("Admin/UserCard_inner_")
    end

    it "leaves unknown placeholders unchanged" do
      result = described_class.interpolate(
        "{unknown}_",
        component_name: "ExampleComponent",
        class_name: "component"
      )

      expect(result).to eq("{unknown}_")
    end
  end

  describe ".escape_for_css_selector" do
    it "escapes forward slashes" do
      expect(
        described_class.escape_for_css_selector("Admin/UserCardComponent_component_abc12345")
      ).to eq("Admin\\/UserCardComponent_component_abc12345")
    end
  end
end
