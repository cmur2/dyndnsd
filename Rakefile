# frozen_string_literal: true

require 'bundler/gem_tasks'
require 'rspec/core/rake_task'
require 'rubocop/rake_task'

RSpec::Core::RakeTask.new(:spec)
RuboCop::RakeTask.new

desc 'Run experimental solargraph type checker'
task :solargraph do
  sh 'solargraph typecheck'
end

# renovate: datasource=github-tags depName=hadolint/hadolint
hadolint_version = 'v2.14.0'

# renovate: datasource=github-tags depName=aquasecurity/trivy
trivy_version = 'v0.61.0'

namespace :docker do
  ci_image = 'cmur2/dyndnsd:ci'

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
    sh "./trivy image #{ci_image}"
  end

  desc 'End-to-end test the CI Docker image'
  task :e2e do
    sh <<~SCRIPT
      echo -n '{}' > e2e/db.json
      chmod a+w e2e/db.json
    SCRIPT
    sh "docker run -d --name=dyndnsd-ci -v $(pwd)/e2e:/etc/dyndnsd -p 8080:8080 -p 5353:5353 #{ci_image}"
    sh 'sleep 5'
    puts '----------------------------------------'
    # `dig` needs `sudo apt-get install -y -q dnsutils`
    sh <<~SCRIPT
      curl -s -o /dev/null -w '%{http_code}' 'http://localhost:8080/' | grep -q '401'
      curl -s 'http://foo:secret@localhost:8080/nic/update?hostname=foo.dyn.example.org&myip=1.2.3.4' | grep -q 'good'
      curl -s 'http://foo:secret@localhost:8080/nic/update?hostname=foo.dyn.example.org&myip=1.2.3.4' | grep -q 'nochg'
      dig +short AXFR 'dyn.example.org' @127.0.0.1 -p 5353 | grep -q '1.2.3.4'
    SCRIPT
    puts '----------------------------------------'
    sh <<~SCRIPT
      docker logs dyndnsd-ci
      docker container rm -f -v dyndnsd-ci
      rm e2e/db.json
    SCRIPT
  end
end

namespace :bundle do
  desc 'Check for vulnerabilities with bundler-audit'
  task :audit do
    sh 'bundler-audit check --ignore GHSA-vvfq-8hwr-qm4m' if !RUBY_VERSION.start_with?('3.0')
  end
end

task default: [:rubocop, :spec, 'bundle:audit']

desc 'Run all tasks desired for CI'
task ci: [:default, 'docker:lint', :build, 'docker:build', 'docker:e2e']
