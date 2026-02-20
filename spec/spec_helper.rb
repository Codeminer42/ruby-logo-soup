# frozen_string_literal: true

if ENV["COVERAGE"] == "1"
  require "simplecov"
  require "simplecov-console"
  require "simplecov-lcov"

  SimpleCov.formatters = SimpleCov::Formatter::MultiFormatter.new([
    SimpleCov::Formatter::Console,
    SimpleCov::Formatter::HTMLFormatter,
    SimpleCov::Formatter::LcovFormatter
  ])

  SimpleCov.start do
    enable_coverage :branch
    add_filter "/spec/"
  end
end

require "logosoup"

RSpec.configure do |config|
  config.disable_monkey_patching!
  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.order = :random
  Kernel.srand config.seed
end
