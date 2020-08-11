# frozen_string_literal: true

require 'rubygems'
require 'bundler/setup'
require 'rack/test'

require 'dyndnsd'

require_relative 'support/dummy_database'
require_relative 'support/dummy_updater'
