
$:.push File.expand_path("../lib", __FILE__)

require 'dyndnsd/version'

Gem::Specification.new do |s|
  s.name  = 'dyndnsd'
  s.version = Dyndnsd::VERSION
  s.summary = 'dyndnsd.rb'
  s.description = 'A small, lightweight and extensible DynDNS server written with Ruby and Rack.'
  s.author  = 'Christian Nicolai'
  s.email = 'chrnicolai@gmail.com'
  s.license = 'Apache License Version 2.0'
  s.homepage  = 'https://github.com/cmur2/dyndnsd'

  s.files = `git ls-files`.split($/)
  s.test_files = s.files.grep(%r{^(test|spec|features)/})

  s.require_paths = ['lib']

  s.executables = ['dyndnsd']

  s.add_runtime_dependency 'rack', '~> 1.6'
  s.add_runtime_dependency 'json'
  s.add_runtime_dependency 'metriks'

  s.add_development_dependency 'bundler', '~> 1.3'
  s.add_development_dependency 'rake'
  s.add_development_dependency 'rspec'
  s.add_development_dependency 'rack-test'
end
