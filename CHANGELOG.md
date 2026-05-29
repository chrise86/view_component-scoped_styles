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
