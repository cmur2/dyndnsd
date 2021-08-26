# Changelog

## 3.4.4

OTHER:

- re-release 3.4.3 to rebuild Docker image with security vulnerabilities fixes

## 3.4.3 (August 20th, 2021)

OTHER:

- re-release 3.4.2 to rebuild Docker image with security vulnerabilities fixes

## 3.4.2 (July 30, 2021)

IMPROVEMENTS:

- move from OpenTracing to OpenTelemetry for experimental tracing feature

OTHER:

- re-release 3.4.1 to rebuild Docker image with security vulnerabilities fixes
- adopt Renovate for dependency updates

## 3.4.1 (April 15, 2021)

OTHER:

- update base of Docker image to Alpine 3.13.5 to fix security vulnerabilities

## 3.4.0 (April 2, 2021)

IMPROVEMENTS:

- **change** Docker image to run as non-root user `65534` by default, limits attack surface for security and gives OpenShift compatibility

## 3.3.3 (April 1, 2021)

OTHER:

- update base of Docker image to Alpine 3.13.4 to fix security vulnerabilities

## 3.3.2 (February 20, 2021)

OTHER:

- update to use `docker/build-push-action@v2` for releasing Docker image in GHA

## 3.3.1 (February 18, 2021)

OTHER:

- update base of Docker image to Alpine 3.13.2 to fix security vulnerabilities

## 3.3.0 (January 18, 2021)

OTHER:

- update base of Docker image to Alpine 3.13

## 3.2.0 (January 14, 2021)

IMPROVEMENTS:

- Add Ruby 3.0 support

## 3.1.3 (December 20, 2020)

OTHER:

- fix Docker image release process in Github Actions CI, 3.1.2 was not released as a Docker image

## 3.1.2 (December 20, 2020)

OTHER:

- fixes vulnerabilities in Docker image by using updated Alpine base image
- start using Github Actions CI for tests and drop Travis CI

## 3.1.1 (October 3, 2020)

IMPROVEMENTS:

- Use webrick gem which contains fixes against [CVE-2020-25613](https://www.ruby-lang.org/en/news/2020/09/29/http-request-smuggling-cve-2020-25613/)

## 3.1.0 (August 19, 2020)

IMPROVEMENTS:

- Add officially maintained [Docker image for dyndnsd](https://hub.docker.com/r/cmur2/dyndnsd)

## 3.0.0 (July 29, 2020)

IMPROVEMENTS:

- Drop EOL Ruby 2.4 and lower support, now minimum version supported is Ruby 2.5

## 2.3.1 (July 27, 2020)

IMPROVEMENTS:

- Fix annoying error message `log writing failed. can't be called from trap context` on shutdown by not attempting to log redundant information there

## 2.3.0 (July 20, 2020)

IMPROVEMENTS:

- Allow enabling debug logging
- Add updater that uses [DNS zone transfers via AXFR (RFC5936)](https://tools.ietf.org/html/rfc5936) to allow any secondary nameserver(s) to fetch the zone contents after (optionally) receiving a [DNS NOTIFY (RFC1996)](https://tools.ietf.org/html/rfc1996) request

## 2.2.0 (March 6, 2020)

IMPROVEMENTS:

- Refactor gemspec based on [recommendations](https://piotrmurach.com/articles/writing-a-ruby-gem-specification/) so tests are now excluded from gem and binaries move to `./exe` directory
- Adopt Ruby 2.3 frozen string literals for source code potentially reducing memory consumption

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

- Support dropping privileges on startup, also affects external commands run
- Add [metriks](https://github.com/eric/metriks) support for basic metrics in the process title
- Detach from child processes running external commands to avoid zombie processes

## 1.0.0 (April 28, 2013)

NEW FEATURES:

- Initial 1.0 release
