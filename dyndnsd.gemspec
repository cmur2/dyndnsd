# frozen_string_literal: true

require_relative 'lib/dyndnsd/version'

Gem::Specification.new do |s|
  s.name = 'dyndnsd'
  s.version = Dyndnsd::VERSION
  s.summary = 'dyndnsd.rb'
  s.description = 'A small, lightweight and extensible DynDNS server written with Ruby and Rack.'
  s.author = 'Christian Nicolai'

  s.homepage = 'https://github.com/cmur2/dyndnsd'
  s.license = 'Apache-2.0'
  s.metadata = {
    'bug_tracker_uri' => "#{s.homepage}/issues",
    'changelog_uri' => "#{s.homepage}/blob/master/CHANGELOG.md",
    'source_code_uri' => s.homepage
  }

  s.files = `git ls-files -z`.split("\x0").select do |f|
    f.match(%r{^(init.d|lib)/})
  end
  s.require_paths = ['lib']
  s.bindir = 'exe'
  s.executables = ['dyndnsd']
  s.extra_rdoc_files = Dir['README.md', 'CHANGELOG.md', 'LICENSE']

  s.required_ruby_version = '>= 2.5'

  s.add_runtime_dependency 'async-dns', '~> 1.2.0'
  s.add_runtime_dependency 'jaeger-client', '~> 1.1.0'
  s.add_runtime_dependency 'metriks'
  s.add_runtime_dependency 'opentracing', '~> 0.5.0'
  s.add_runtime_dependency 'rack', '~> 2.0'
  s.add_runtime_dependency 'rack-tracer', '~> 0.9.0'
  s.add_runtime_dependency 'webrick', '>= 1.6.1'

  s.add_development_dependency 'bundler'
  s.add_development_dependency 'bundler-audit', '~> 0.7.0'
  s.add_development_dependency 'rack-test'
  s.add_development_dependency 'rake'
  s.add_development_dependency 'rspec'
  s.add_development_dependency 'rubocop', '~> 1.3.0'
  # s.add_development_dependency 'solargraph', '~> 0.39.0'
end
