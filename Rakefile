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

# renovate: datasource=github-tags depName=hadolint/hadolint
hadolint_version = 'v2.8.0'

desc 'Run hadolint for Dockerfile linting'
task :hadolint do
  sh "wget -q -O ./hadolint https://github.com/hadolint/hadolint/releases/download/#{hadolint_version}/hadolint-Linux-x86_64"
  sh 'chmod a+x ./hadolint'
  sh './hadolint --ignore DL3018 docker/Dockerfile'
end

task default: [:rubocop, :spec, 'bundle:audit', :solargraph]

desc 'Run all tasks desired for CI'
task ci: ['solargraph:init', :default, :hadolint, :build]
