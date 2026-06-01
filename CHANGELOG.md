## [0.5.0] - 2026-06-01

### Breaking changes

**This release is incompatible with 0.4.x.** Scoped class names and compiled CSS selectors change unless you opt into the previous behaviour.

- Default `css_class_prefix` is now `"{class_name}_"` instead of `"c-"`. For example, `.component` becomes `.component_a1b2c3d4` rather than `.c-a1b2c3d4`.
- `css_class_prefix` is a template string supporting `{class_name}` and `{component_name}` (namespaces joined by `/`). Per-component `css_class_prefix` uses the same interpolation.
- Forward slashes in interpolated class names are escaped in compiled CSS selectors (e.g. `Admin/UserCardComponent` → `Admin\/UserCardComponent`).

**Upgrade from 0.4.x:** set `config.css_class_prefix = "c-"` in your initializer (and per-component overrides if any) to keep existing class names, then regenerate `components.scoped.css` in development. Otherwise update templates and markup to match the new scoped class names.

### Added

- `ViewComponent::ScopedStyles::CssClassPrefix` for prefix interpolation and CSS selector escaping.

## [0.4.1] - 2026-06-01

### Fixed

- Railtie component discovery now respects the configured `components_path` instead of always scanning `app/components`.

## [0.4.0] - 2026-05-31

### Added

- `assets_path` and `stylesheet_name` global configuration options to customize where the bundled scoped stylesheet is written (defaults: `app/assets/stylesheets` and `components.scoped.css`).

## [0.3.0] - 2026-05-29

### Added

- `css_class_prefix` global configuration option and per-component `css_class_prefix` method to customize the prefix for scoped class names (default: `"c-"`).

## [0.2.0] - 2026-05-29

### Added

- `ignored_css_classes` to keep specific selectors unscoped in generated CSS; `component_class("name")` returns the original class name for ignored classes.

### Changed

- Style registration and writes to `components.scoped.css` run only in development; production and test use the committed stylesheet.

### Fixed

- Require `digest` explicitly and qualify `Digest::MD5` so scoped class IDs generate correctly in test and other load orders.
- Railtie development reload uses an initializer so `to_prepare` runs after Rails is fully loaded.

## [0.1.0] - 2026-05-28

- Initial release
