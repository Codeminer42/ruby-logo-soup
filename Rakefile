# frozen_string_literal: true

require 'rake'
require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new(:spec)

desc 'Run RuboCop'
task :rubocop do
  sh 'bundle exec rubocop -c .rubocop.yml'
end

desc 'Run Brakeman (best-effort static scan)'
task :brakeman do
  # --force makes Brakeman run even if this isn't a Rails app.
  sh 'bundle exec brakeman --force'
end

desc 'Run all checks'
task default: %i[spec rubocop brakeman]
