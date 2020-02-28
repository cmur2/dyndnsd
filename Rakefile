require 'bundler/gem_tasks'
require 'rspec/core/rake_task'
require 'rubocop/rake_task'
require 'bundler/audit/task'

RSpec::Core::RakeTask.new(:spec)
RuboCop::RakeTask.new
Bundler::Audit::Task.new

task :solargraph do
  sh 'solargraph typecheck'
end

task default: [:rubocop, :spec, 'bundle:audit']
