
require 'rubygems'
require 'bundler/setup'
require 'rack/test'

require 'dyndnsd'
require 'support/dummy_database'
require 'support/dummy_updater'

RSpec.configure do |config|
  config.expect_with(:rspec) { |c| c.syntax = :should }
end
