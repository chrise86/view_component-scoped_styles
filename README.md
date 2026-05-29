# ViewComponent::ScopedStyles [![Gem Version](https://badge.fury.io/rb/view_component-scoped_styles.svg)](https://badge.fury.io/rb/view_component-scoped_styles)

Scoped, colocated CSS for [ViewComponent](https://viewcomponent.org/).

Avoids collisions by rewriting class selectors to stable, content-derived names.

E.g. `.button` becomes `.c-a1b2c3d4`

## Table of Contents

- [ViewComponent::ScopedStyles ](#viewcomponentscopedstyles-)
  - [Table of Contents](#table-of-contents)
  - [Installation](#installation)
  - [Usage](#usage)
    - [1. Using a sidecar stylesheet](#1-using-a-sidecar-stylesheet)
    - [2. Using a styles block in the component](#2-using-a-styles-block-in-the-component)
    - [Referencing classes](#referencing-classes)
    - [Ignoring classes](#ignoring-classes)
    - [Using the scoped CSS](#using-the-scoped-css)
  - [Configuration](#configuration)
  - [Related projects](#related-projects)
  - [Development](#development)
  - [Contributing](#contributing)
  - [License](#license)
  - [Code of Conduct](#code-of-conduct)

## Installation

Install the gem and add to the application's Gemfile by executing:

```bash
bundle add view_component-scoped_styles
```

Or add it to the Gemfile manually:

```ruby
gem "view_component-scoped_styles"
```

If bundler is not being used to manage dependencies, install the gem by executing:

```bash
gem install view_component-scoped_styles
```

## Usage

Include the module in any component class you would like to use with scoped CSS.

```ruby
class ExampleComponent < ViewComponent::Base
  include ViewComponent::ScopedStyles
end
```

CSS can be written in two ways:

### 1. Using a sidecar stylesheet

Learn more about sidecar [here](https://viewcomponent.org/guide/generators.html#place-the-view-in-a-sidecar-directory).

```bash
bin/rails generate view_component:component Example title --sidecar

      create  app/components/example_component.rb
      invoke  test_unit
      create    test/components/example_component_test.rb
      invoke  erb
      create    app/components/example_component/example_component.html.erb

```

Then add a matching stylesheet in the sidecar directory:

```css
/* app/components/example_component/example_component.css */

.component {
  position: relative;
}
```

### 2. Using a styles block in the component

```ruby
# app/components/example_component.rb

class ExampleComponent < ViewComponent::Base
  include ViewComponent::ScopedStyles

  styles do
    <<~CSS
      .component {
        position: relative;
      }
    CSS
  end
end
```

**NB:** Using a styles block will take precedence over a sidecar stylesheet.

### Referencing classes

Use the `component_class` helper inside component templates to refer to the scoped CSS classes:

```erb
<div class="<%= component_class %>">
  My component content
</div>
```

The default selector is `.component` but you can change this by defining `component_css_class` in your component:

```ruby
class ExampleComponent < ViewComponent::Base
  include ViewComponent::ScopedStyles

  component_css_class "example"

  styles do
    <<~CSS
      .example {
        position: relative;
      }
    CSS
  end
end
```

`component_class` takes an optional string argument to reference other classes in the CSS:

```ruby
class ExampleComponent < ViewComponent::Base
  include ViewComponent::ScopedStyles

  component_css_class "example"

  styles do
    <<~CSS
      .example {
        position: relative;
      }

      .inner {
        position: absolute;
      }
    CSS
  end
end
```

```erb
<div class="<%= component_class %>">
  My component content

  <div class="<%= component_class("inner") %>">
    Inner content
  </div>
</div>
```

### Ignoring classes

Ignored classes are left unchanged in generated CSS:

```ruby
class ExampleComponent < ViewComponent::Base
  include ViewComponent::ScopedStyles

  ignored_css_classes "is-open", "active"

  styles do
    <<~CSS
      .component { ... }
      .is-open { ... }  # stays .is-open in components.scoped.css
    CSS
  end
end
```
In your view, you can either reference the class directly:
```erb
<div class="<%= component_class %> is-open">
```
or via the `component_class` helper:
```erb
<div class="<%= component_class %> <%= component_class("is-open") %>">
```

### Using the scoped CSS

All scoped CSS will be compiled into `app/assets/stylesheets/components.scoped.css`.

You should import this stylesheet within your app:

```css
/* app/assets/stylesheets/application.css */

@import url("./components.scoped.css");
```

## Configuration

Run the install generator in your Rails app:

```bash
bin/rails generate view_component:scoped_styles:install
```

That creates `config/initializers/view_component_scoped_styles.rb` with the same defaults as `ViewComponent::ScopedStyles::Configuration`.

Or create the initializer manually:

```ruby
ViewComponent::ScopedStyles.configure do |config|
  # Where ViewComponent classes live (relative to Rails.root). Default: "app/components"
  config.components_path = File.join("app", "components")

  # Optional @layer name for components.scoped.css (e.g. "components"). Default: nil.
  config.components_layer = nil
end
```

| Option | Default | Description |
| --- | --- | --- |
| `components_path` | `"app/components"` | Where ViewComponent classes live, relative to `Rails.root`. |
| `components_layer` | `nil` | When set, wraps generated CSS in `@layer <name> { ... }` for cascade control. |

## Related projects

This gem was heavily inspired by Partials Fx, and indeed takes its foundations from it, modified to work with ViewComponent instead.

- https://github.com/Rails-Designer/partials_fx
- https://github.com/aileron-inc/view_component_scoped_css
- https://github.com/amkisko/style_capsule.rb

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/chrise86/view_component-scoped_styles. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/chrise86/view_component-scoped_styles/blob/master/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the ViewComponent::ScopedStyles project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/chrise86/view_component-scoped_styles/blob/master/CODE_OF_CONDUCT.md).
