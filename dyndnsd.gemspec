
$LOAD_PATH.push File.expand_path('lib', __dir__)

require 'dyndnsd/version'

Gem::Specification.new do |s|
  s.name = 'dyndnsd'
  s.version = Dyndnsd::VERSION
  s.summary = 'dyndnsd.rb'
  s.description = 'A small, lightweight and extensible DynDNS server written with Ruby and Rack.'
  s.author = 'Christian Nicolai'
  s.email = 'chrnicolai@gmail.com'
  s.homepage = 'https://github.com/cmur2/dyndnsd'
  s.license = 'Apache-2.0'

  s.files = `git ls-files`.split($INPUT_RECORD_SEPARATOR)
  s.test_files = s.files.grep(%r{^(test|spec|features)/})
  s.require_paths = ['lib']
  s.executables = ['dyndnsd']

  s.required_ruby_version = '>= 2.3'

  s.add_runtime_dependency 'rack', '~> 2.0'
  s.add_runtime_dependency 'json'
  s.add_runtime_dependency 'metriks'
  s.add_runtime_dependency 'opentracing', '~> 0.5.0'
  s.add_runtime_dependency 'rack-tracer', '~> 0.8.0'
  s.add_runtime_dependency 'jaeger-client', '~> 0.10.0'

  s.add_development_dependency 'bundler', '< 2'
  s.add_development_dependency 'rake'
  s.add_development_dependency 'rspec'
  s.add_development_dependency 'rack-test'
  s.add_development_dependency 'rubocop', '~> 0.62.0'
  s.add_development_dependency 'bundler-audit'
end
