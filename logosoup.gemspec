# frozen_string_literal: true

require_relative "lib/logosoup/version"

Gem::Specification.new do |spec|
  spec.name = "logosoup"
  spec.version = LogoSoup::VERSION
  spec.authors = ["Alexandre Camillo"]
  spec.email = ["alexandre.camillo@codeminer42.com"]

  spec.summary = "Framework-agnostic logo normalization (CSS style output)"
  spec.description = "Compute CSS sizing/alignment styles for SVG and raster logos with consistent perceived rendering."
  spec.homepage = "https://example.com/logosoup"
  spec.license = "MIT"

  spec.required_ruby_version = ">= 3.1", "< 4.0"

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
  spec.add_dependency "nokogiri", ">= 1.15", "< 2"
  spec.add_dependency "ruby-vips", ">= 2.2", "< 3"

  # Development dependencies
  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "rspec", "~> 3.12"

  # Coverage (for CI)
  spec.add_development_dependency "simplecov", "~> 0.22"
  spec.add_development_dependency "simplecov-lcov", "~> 0.8"
  spec.add_development_dependency "simplecov-console", "~> 0.9"
  spec.add_development_dependency "minitest", ">= 5", "< 5.26"

  spec.add_development_dependency "rubocop", "~> 1.50"
  spec.add_development_dependency "rubocop-github", "~> 0.26"
  spec.add_development_dependency "rubocop-performance", "~> 1.26"
  # Keep rubocop-rails transitive dependencies compatible with Ruby 2.7/3.0 CI jobs.
  spec.add_development_dependency "activesupport", ">= 6.1", "< 7.1"

  spec.add_development_dependency "brakeman", "~> 6.1"
end
