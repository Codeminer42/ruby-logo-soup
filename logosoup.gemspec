# frozen_string_literal: true

require_relative "lib/logo_soup/version"

Gem::Specification.new do |spec|
  spec.name = "logosoup"
  spec.version = LogoSoup::VERSION
  spec.authors = ["Alexandre Camillo"]
  spec.email = ["alexandre.camillo@codeminer42.com"]

  spec.summary = "Framework-agnostic logo normalization (CSS style output)"
  spec.description = "Compute CSS sizing/alignment styles for SVG and raster logos with consistent perceived rendering."
  spec.homepage = "https://example.com/logosoup"
  spec.license = "MIT"

  spec.required_ruby_version = ">= 2.7", "< 4.0"

  spec.metadata["rubygems_mfa_required"] = "true"

  spec.files = Dir.chdir(__dir__) do
    Dir[
      "README.md",
      "LICENSE.txt",
      "CHANGELOG.md",
      "lib/**/*.rb"
    ]
  end

  spec.require_paths = ["lib"]

  # Runtime dependencies
  spec.add_dependency "nokogiri", ">= 1.15", "< 3"
  spec.add_dependency "ruby-vips", ">= 2.2", "< 3"

  # Development dependencies
  spec.add_development_dependency "rake", ">= 13.0"
  spec.add_development_dependency "rspec", "~> 3.12"

  # Coverage (for CI)
  spec.add_development_dependency "simplecov", "~> 0.22"
  spec.add_development_dependency "simplecov-lcov", "~> 0.8"
  spec.add_development_dependency "simplecov-console", "~> 0.9"

  # Pin RuboCop to a line that still supports Ruby 2.7.
  spec.add_development_dependency "rubocop", "~> 1.50"
  spec.add_development_dependency "rubocop-github"
  spec.add_development_dependency "rubocop-performance"

  spec.add_development_dependency "brakeman", "~> 6.1"
end
