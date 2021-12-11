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

# renovate: datasource=github-tags depName=aquasecurity/trivy
trivy_version = 'v0.21.2'

namespace :docker do
  desc 'Lint Dockerfile'
  task :lint do
    sh "if [ ! -e ./hadolint ]; then wget -q -O ./hadolint https://github.com/hadolint/hadolint/releases/download/#{hadolint_version}/hadolint-Linux-x86_64; fi"
    sh 'chmod a+x ./hadolint'
    sh './hadolint --ignore DL3018 docker/Dockerfile'
    sh './hadolint --ignore DL3018 --ignore DL3028 docker/ci/Dockerfile'
  end

  desc 'Build CI Docker image'
  task :build do
    sh 'docker build -t cmur2/dyndnsd:ci -f docker/ci/Dockerfile .'
  end

  desc 'Scan CI Docker image for vulnerabilities'
  task :scan do
    ver = trivy_version.gsub('v', '')
    sh "if [ ! -e ./trivy ]; then wget -q -O - https://github.com/aquasecurity/trivy/releases/download/v#{ver}/trivy_#{ver}_Linux-64bit.tar.gz | tar -xzf - trivy; fi"
    sh './trivy cmur2/dyndnsd:ci'
  end
end

task default: [:rubocop, :spec, 'bundle:audit', :solargraph]

desc 'Run all tasks desired for CI'
task ci: ['solargraph:init', :default, 'docker:lint', :build, 'docker:build']
