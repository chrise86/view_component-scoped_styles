# frozen_string_literal: true

require_relative "lib/view_component/scoped_styles/version"

Gem::Specification.new do |spec|
  spec.name = "view_component-scoped_styles"
  spec.version = ViewComponent::ScopedStyles::VERSION
  spec.authors = ["Chris Edwards"]
  spec.email = ["chris@chrise.net"]

  spec.summary = "Scoped, colocated CSS for ViewComponent components."
  spec.description = "Rewrites ViewComponent component styles to content-derived class names, bundles them into a single stylesheet, and provides helpers to use those classes in templates."
  spec.homepage = "https://github.com/chrise86/view_component-scoped_styles"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.2.0"

  github_url = "https://github.com/chrise86/view_component-scoped_styles"
  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = github_url
  spec.metadata["changelog_uri"] = "#{github_url}/blob/main/CHANGELOG.md"
  spec.metadata["rubygems_mfa_required"] = "true"

  spec.files =
    ::Dir.chdir ::File.expand_path(__dir__) do
      ::Dir['lib/**/*', 'LICENSE.md', 'Rakefile', 'README.md']
    end

  spec.add_dependency 'rails', '>= 7.0', '< 9'
  spec.add_dependency 'view_component', '>= 3.0'

  spec.add_development_dependency "rubocop"
  spec.add_development_dependency "rubocop-rails-omakase"
  spec.add_development_dependency "rspec"
  spec.add_development_dependency "rake", "~> 13.0"
end
