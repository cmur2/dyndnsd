# Changelog

## 2.2.0

IMPROVEMENTS:

- Refactor gemspec based on [recommendations](https://piotrmurach.com/articles/writing-a-ruby-gem-specification/) so tests are now excluded from gem and binaries move to `./exe` directory

## 2.1.1 (March 1, 2020)

IMPROVEMENTS:

- Fix potential `nil` cases detected by [Sorbet](https://sorbet.org) including refactorings

## 2.1.0 (March 1, 2020)

IMPROVEMENTS:

- Add Ruby 2.7 support
- Add [solargraph](https://github.com/castwide/solargraph) to dev tooling as Ruby Language Server usable e.g. for IDEs (used solargraph version not compatible with Ruby 2.7 as bundler-audit 0.6.x requires old `thor` gem)
- Document code using YARD tags, e.g. for type information and better code completion

## 2.0.0 (January 25, 2019)

IMPROVEMENTS:

- Drop Ruby 2.2 and lower support
- Better protocol compliance by returning `badauth` in response body on HTTP 401 errors
- Better code maintainability by refactorings
- Update dependencies, mainly `rack` to new major version 2
- Add Ruby 2.5 and Ruby 2.6 support
- Add experimental [OpenTracing](https://opentracing.io/) support with [CNCF Jaeger](https://github.com/jaegertracing/jaeger)
- Support host offlining by deleting the associated DNS records
- Add textfile reporter to write Graphite-style metrics (also compatible with [Prometheus](https://prometheus.io/)) into a file

## 1.6.1 (October 31, 2017)

IMPROVEMENTS:

- Fix broken password check affecting all previous releases

## 1.6.0 (December 7, 2016)

IMPROVEMENTS:

- Support providing an IPv6 address in addition to a IPv4 for the same hostname

## 1.5.0 (November 30, 2016)

IMPROVEMENTS:

- Drop Ruby 1.8.7 support
- Pin `json` gem to allow supporting Ruby 1.9.3
- Support determining effective client IP address also from `X-Real-IP` header

## 1.4.0 (November 27, 2016)

IMPROVEMENTS:

- Pin `rack` gem to allow supporting Ruby versions < 2.2.2
- Support IPv6 addresses

## 1.3.0 (October 8, 2013)

IMPROVEMENTS:

- Handle `SIGTERM` \*nix signal properly and shutdown the daemon

## 1.2.2 (June 8, 2013)

IMPROVEMENTS:

- Add proper logging to the provided init script for dyndnsd.rb

## 1.2.1 (June 5, 2013)

IMPROVEMENTS:

- Fix bug in previous release related to metrics preventing startup

## 1.2.0 (May 29, 2013)

IMPROVEMENTS:

- Support sending metrics to graphite via undocumented `graphite:` section in configuration file

## 1.1.0 (April 30, 2013)

IMPROVEMENTS:

- Support dropping priviliges on startup, also affects external commands run
- Add [metriks](https://github.com/eric/metriks) support for basic metrics in the process title
- Detach from child processes running external commands to avoid zombie processes

## 1.0.0 (April 28, 2013)

NEW FEATURES:

- Initial 1.0 release
