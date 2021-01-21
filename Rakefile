# frozen_string_literal: true

require 'bundler/gem_tasks'
require 'rspec/core/rake_task'
require 'rubocop/rake_task'
require 'bundler/audit/task'

RSpec::Core::RakeTask.new(:spec)
RuboCop::RakeTask.new
Bundler::Audit::Task.new

desc 'Run experimental solargraph type checker'
task :solargraph do
  sh 'solargraph typecheck'
end

namespace :solargraph do
  desc 'Should be run by developer once to prepare initial solargraph usage (fill caches etc.)'
  task :init do
    sh 'solargraph download-core'
  end
end

desc 'Run hadolint for Dockerfile linting'
task :hadolint do
  sh 'docker run --rm -i hadolint/hadolint:v1.18.0 hadolint --ignore DL3018 - < docker/Dockerfile'
end

desc 'Run experimental steep type checker'
task :steep do
  sh 'steep check'
end

namespace :steep do
  desc 'Output coverage stats from steep'
  task :stats do
    sh 'steep stats --log-level=fatal | awk -F\',\' \'{ printf "%-50s %-9s %-12s %-14s %-10s\n", $2, $3, $4, $5, $7 }\''
  end
end

task default: [:rubocop, :spec, 'bundle:audit', :solargraph, :steep]

desc 'Run all tasks desired for CI'
task ci: ['solargraph:init', :default, :hadolint]
