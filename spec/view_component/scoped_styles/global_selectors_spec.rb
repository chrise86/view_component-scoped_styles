# frozen_string_literal: true

RSpec.describe "Global CSS selectors" do
  def component_with_styles(css)
    Class.new do
      include ViewComponent::ScopedStyles
      styles { css }
    end
  end

  it "keeps global occurrences unchanged while scoping the same class elsewhere" do
    component = component_with_styles(".component:global(.active) .active { color: red; }")
    instance = component.new

    expect(component.component_styles).to eq(
      ".#{instance.component_class}.active .#{instance.component_class('active')} { color: red; }"
    )
    expect(instance.component_class("active")).to match(/\Aactive_[0-9a-f]{8}\z/)
  end

  it "returns global-only names from the helper and chooses a local root" do
    component = component_with_styles(":global(.external) .content { color: red; }")
    instance = component.new

    expect(instance.component_class("external")).to eq("external")
    expect(instance.component_class).to eq(instance.component_class("content"))
    expect(component.component_styles).to eq(".external .#{instance.component_class} { color: red; }")
  end

  it "supports stylesheets containing only global classes" do
    component = component_with_styles(":global(.external) { color: red; }")

    expect(component.component_styles).to eq(".external { color: red; }")
    expect(component.new.component_class).to eq("external")
  end

  it "honors a global root class when local classes are also present" do
    component = component_with_styles(":global(.component) .label { color: red; }")

    expect(component.new.component_class).to eq("component")
    expect(component.component_styles).to eq(".component .#{component.new.component_class('label')} { color: red; }")
  end

  it "handles nested selector functions, attributes, and multiple global markers" do
    component = component_with_styles(
      '.component:has(:global(.external:not(.disabled)[data-name="a)b"])) :global(.icon) .label { color: red; }'
    )
    instance = component.new

    expect(component.component_styles).to eq(
      ".#{instance.component_class}:has(.external:not(.disabled)[data-name=\"a)b\"]) .icon .#{instance.component_class('label')} { color: red; }"
    )
  end

  it "supports bare global and local scope switches and resets at commas and rules" do
    component = component_with_styles(
      ".component :global .external .icon :local(.label) .tail, .other { color: red; } .external { color: blue; }"
    )
    instance = component.new

    expect(component.component_styles).to eq(
      ".#{instance.component_class} .external .icon .#{instance.component_class('label')} .tail, .#{instance.component_class('other')} { color: red; } .#{instance.component_class('external')} { color: blue; }"
    )
  end

  it "resets bare scope inside selector functions" do
    component = component_with_styles(".component:is(:global .external, .local) .tail { color: red; }")
    instance = component.new

    expect(component.component_styles).to eq(
      ".#{instance.component_class}:is(.external, .#{instance.component_class('local')}) .#{instance.component_class('tail')} { color: red; }"
    )
  end

  it "supports bare local scope after global scope" do
    component = component_with_styles(":global .external :local .component .label { color: red; }")
    instance = component.new

    expect(component.component_styles).to eq(
      ".external .#{instance.component_class} .#{instance.component_class('label')} { color: red; }"
    )
  end

  it "supports separate global functions in a selector list" do
    component = component_with_styles(":global(.first), :global(.second), .component { color: red; }")

    expect(component.component_styles).to eq(
      ".first, .second, .#{component.new.component_class} { color: red; }"
    )
  end

  it "rejects selector lists inside a global function to avoid changing selector meaning" do
    component = component_with_styles(".component :global(.first, .second) { color: red; }")

    expect { component.component_styles }.to raise_error(ArgumentError, /separate :global/)
  end

  it "processes sidecar styles and nested rules inside at-rules" do
    component = Class.new do
      include ViewComponent::ScopedStyles
    end
    css = "@media (min-width: 10px) { .component { &:global(.active) .label { color: red; } } }"
    allow(component).to receive(:sidecar_files).with(["css"]).and_return(["component.css"])
    allow(File).to receive(:exist?).with("component.css").and_return(true)
    allow(File).to receive(:read).with("component.css").and_return(css)
    instance = component.new

    expect(component.component_styles).to eq(
      "@media (min-width: 10px) { .#{instance.component_class} { &.active .#{instance.component_class('label')} { color: red; } } }"
    )
  end

  it "preserves comments, attribute values, declarations, and similar pseudo-class names" do
    css = <<~CSS
      /* :global(.comment) { } */
      .component[data-name=":global(.attribute)"]:globalized {
        content: ":global(.content) { ; }";
        background: url(/assets/icon.svg);
        --selector: :global(.value);
      }
    CSS
    component = component_with_styles(css)

    expect(component.component_styles).to eq(css.sub(".component[", ".#{component.new.component_class}["))
    %w[comment attribute content svg value].each do |name|
      expect(component.new.component_class(name)).to be_nil
    end
  end

  it "processes selectors in scope and supports at-rules" do
    css = <<~CSS
      @supports selector(:global(.external)) and (background: url("/icon.svg")) {
        @scope (.component) to (:global(.boundary)) {
          .label { color: red; }
        }
      }
    CSS
    component = component_with_styles(css)
    instance = component.new

    expect(component.component_styles).to eq(<<~CSS)
      @supports selector(.external) and (background: url("/icon.svg")) {
        @scope (.#{instance.component_class}) to (.boundary) {
          .#{instance.component_class("label")} { color: red; }
        }
      }
    CSS
    expect(instance.component_class("svg")).to be_nil
  end

  it "keeps component references working alongside global selectors" do
    target = component_with_styles(".component { color: blue; }")
    stub_const("GlobalTargetComponent", target)
    component = component_with_styles(".component:global(.active) :component(GlobalTargetComponent) { color: red; }")

    expect(component.component_styles).to eq(
      ".#{component.new.component_class}.active .#{target.new.component_class} { color: red; }"
    )
  end

  it "preserves existing hashes for local stylesheets" do
    css = ".component .label { color: red; }"
    component = component_with_styles(css)

    expect(component.new.component_class).to eq("component_#{Digest::MD5.hexdigest(css)[0..7]}")
    expect(component.new.component_class("label")).to eq("label_#{Digest::MD5.hexdigest("#{css}:label")[0..7]}")
  end

  it "warns on the legacy method while preserving ignored classes and cache invalidation" do
    component = component_with_styles(".component.active { color: red; }")
    component.component_styles

    expect { component.ignored_css_classes(:active) }.to output(
      /DEPRECATION WARNING: ignored_css_classes is deprecated.*:global\(\.active\)/
    ).to_stderr
    expect(component.component_styles).to eq(".#{component.new.component_class}.active { color: red; }")
    expect(component.new.component_class("active")).to eq("active")
  end
end
