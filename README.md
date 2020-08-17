# dyndnsd.rb

[![Build Status](https://travis-ci.org/cmur2/dyndnsd.svg?branch=master)](https://travis-ci.org/cmur2/dyndnsd) [![Dependencies](https://badges.depfu.com/badges/4f25da8493f7a29f652ac892fbf9227b/overview.svg)](https://depfu.com/github/cmur2/dyndnsd)

A small, lightweight and extensible DynDNS server written with Ruby and Rack.


## Description

dyndnsd.rb aims to implement a small [DynDNS-compliant](https://help.dyn.com/remote-access-api/) server in Ruby supporting IPv4 and IPv6 addresses. It has an integrated user and hostname database in its configuration file that is used for authentication and authorization. Besides talking the DynDNS protocol it is able to invoke a so-called *updater*, a small Ruby module that takes care of supplying the current hostname => ip mapping to a DNS server.

There are currently two updaters shipped with dyndnsd.rb:
- `zone_transfer_server` that uses [DNS zone transfers via AXFR (RFC5936)](https://tools.ietf.org/html/rfc5936) to allow any secondary nameserver(s) to fetch the zone contents after (optionally) receiving a [DNS NOTIFY (RFC1996)](https://tools.ietf.org/html/rfc1996) request
- `command_with_bind_zone` that writes out a zone file in BIND syntax onto the current system and invokes a user-supplied command afterwards that is assumed to trigger the DNS server (not necessarily BIND since its zone files are read by other DNS servers, too) to reload its zone configuration

Because of the mechanisms used, dyndnsd.rb is known to work only on \*nix systems.

See the [changelog](CHANGELOG.md) before upgrading. The older version 1.x of dyndnsd.rb is still available on [branch dyndnsd-1.x](https://github.com/cmur2/dyndnsd/tree/dyndnsd-1.x).


## General Usage

Install the gem:

	gem install dyndnsd

Create a configuration file in YAML format somewhere:

```yaml
# listen address and port
host: "0.0.0.0"
port: 80
# optional: drop privileges in case you want to but you may need sudo for external commands
user: "nobody"
group: "nogroup"
# logfile is optional, logs to STDOUT otherwise
logfile: "dyndnsd.log"
# internal database file
db: "db.json"
# enable debug mode?
debug: false
# all hostnames are required to be cool-name.example.org
domain: "example.org"
# configure the updater, here we use command_with_bind_zone, params are updater-specific
updater:
  name: "command_with_bind_zone"
  params:
    zone_file: "dyn.zone"
    command: "echo 'Hello'"
    ttl: "5m"
    dns: "dns.example.org."
    email_addr: "admin.example.org."
# user database with hostnames a user is allowed to update
users:
  # 'foo' is username, 'secret' the password
  foo:
    password: "secret"
    hosts:
      - foo.example.org
      - bar.example.org
  test:
    password: "ihavenohosts"
```

Run dyndnsd.rb by:

```bash
dyndnsd /path/to/config.yml
```


### Docker image

There is an officially maintained [Docker image for dyndnsd](https://hub.docker.com/r/cmur2/dyndnsd) available at Dockerhub. The goal is to have a minimal secured image available (currently based on Alpine) that works well for the `zone_transfer_server` updater use case.

Users can make extensions by deriving from the official Docker image or building their own.

The Docker image consumes the same configuration file in YAML format as the gem, inside the container it needs to be mounted/available as `/etc/dyndnsd/config.yml`. the following YAML should be used as a base and extended with user's settings:

```yaml
host: "0.0.0.0"
port: 8080
# omit the logfile: option so logging to STDOUT will happen automatically
db: "/var/lib/db.json"

# User's settings for updater and permissions follow here!
```

more ports might be needed depending on if DNS zone transfer is needed

Run the Docker image exposing the DynDNS-API on host port 8080 via:

```bash
docker run -d --name dyndnsd \
           -p 8080:8080 \
           -v /host/path/to/dyndnsd/config.yml:/etc/dyndnsd/config.yml \
           -v /host/path/to/dyndnsd/db.json:/var/lib/db.json \
           cmur2/dyndnsd:vX.Y.Z
```

*Note*: You may need to expose more then just port 8080 e.g. if you use the `zone_transfer_server` which can be done by appending additional `-p 5353:5353` flags to the `docker run` command.



## Using dyndnsd.rb with any nameserver via DNS zone transfers (AXFR)

By using [DNS zone transfers via AXFR (RFC5936)](https://tools.ietf.org/html/rfc5936) any secondary nameserver can retrieve the DNS zone contents from dyndnsd.rb and serve them to clients.
To speedup propagation after changes dyndnsd.rb can issue a [DNS NOTIFY (RFC1996)](https://tools.ietf.org/html/rfc1996) to inform the nameserver that the DNS zone contents changed and should be fetched even before the time indicated in the SOA record is up.
Currently dyndnsd.rb does not support any authentication for incoming DNS zone transfer requests so it should be isolated from the internet on these ports.

This approach has several advantages:
- dyndnsd.rb can be used in *hidden primary* fashion isolated from client's DNS traffic and does not need to implement full nameserver features
- any existing, production-grade, caching, geo-replicated nameserver setup can be used to pull DNS zone contents from the *hidden primary* dyndnsd.rb and serve it to clients
- any nameserver(s) and dyndnsd.rb do not need to be located on the same host

Example dyndnsd.rb configuration:

```yaml
host: "0.0.0.0"
port: 8245 # the DynDNS.com alternative HTTP port
db: "/opt/dyndnsd/db.json"
domain: "dyn.example.org"
updater:
  name: "zone_transfer_server"
  params:
    # endpoint(s) to listen for incoming zone transfer (AXFR) requests, default 0.0.0.0@53
    server_listens:
    - 127.0.0.1@5300
    # where to send DNS NOTIFY request(s) to on zone content change
    send_notifies:
    - '127.0.0.1'
    # TTL for all records in the zone (in seconds)
    zone_ttl: 300  # 5m
    # zone's NS record(s) (at least one)
    zone_nameservers:
    - "dns.example.org."
    # info for zone's SOA record
    zone_email_address: "admin.example.org."
    # zone's additional A/AAAA records
    zone_additional_ips:
    - "127.0.0.1"
users:
  foo:
    password: "secret"
    hosts:
      - foo.example.org
```


## Using dyndnsd.rb with [NSD](https://www.nlnetlabs.nl/projects/nsd/about/)

NSD is a nice, open source, authoritative-only, low-memory DNS server that reads BIND-style zone files (and converts them into its own database) and has a simple configuration file.

A feature NSD is lacking is the [Dynamic DNS update (RFC2136)](https://tools.ietf.org/html/rfc2136) functionality BIND offers but one can fake it using the following dyndnsd.rb configuration:

```yaml
host: "0.0.0.0"
port: 8245 # the DynDNS.com alternative HTTP port
db: "/opt/dyndnsd/db.json"
domain: "dyn.example.org"
updater:
  name: "command_with_bind_zone"
  params:
    # make sure to register zone file in your nsd.conf
    zone_file: "/etc/nsd3/dyn.example.org.zone"
    # fake DNS update (discards NSD stats)
    command: "nsdc rebuild; nsdc reload"
    ttl: "5m"
    dns: "dns.example.org."
    email_addr: "admin.example.org."
    # specify additional raw BIND-style zone content
    # here: an A record for dyn.example.org itself
    additional_zone_content: "@ IN A 1.2.3.4"
users:
  foo:
    password: "secret"
    hosts:
      - foo.example.org
```

Start dyndnsd.rb before NSD to make sure the zone file exists else NSD complains.


## Using dyndnsd.rb with X

Please provide ideas if you are using dyndnsd.rb with other DNS servers :)


## Advanced topics


### Update URL

The update URL you want to tell your clients (humans or scripts ^^) consists of the following

	http[s]://[USER]:[PASSWORD]@[DOMAIN]:[PORT]/nic/update?hostname=[HOSTNAMES]&myip=[MYIP]&myip6=[MYIP6]

where:

* the protocol depends on your (webserver/proxy) settings
* USER and PASSWORD are needed for HTTP Basic Auth and valid combinations are defined in your config.yaml
* DOMAIN should match what you defined in your config.yaml as domain but may be anything else when using a webserver as proxy
* PORT depends on your (webserver/proxy) settings
* HOSTNAMES is a required list of comma-separated FQDNs (they all have to end with your config.yaml domain) the user wants to update
* MYIP is optional and the HTTP client's IP address will be used if missing
* MYIP6 is optional but if present also requires presence of MYIP


### IP address determination

The following rules apply:

* use any IP address provided via the myip parameter when present, or
* use any IP address provided via the X-Real-IP header e.g. when used behind HTTP reverse proxy such as nginx, or
* use any IP address used by the connecting HTTP client

If you want to provide an additional IPv6 address as myip6 parameter, the myip parameter containing an IPv4 address has to be present, too! No automatism is applied then.


### SSL, multiple listen ports

Use a webserver as a proxy to handle SSL and/or multiple listen addresses and ports. DynDNS.com provides HTTP on port 80 and 8245 and HTTPS on port 443.


### Startup

There is a [Dockerfile](docs/Dockerfile) that can be used to build a Docker image for running dyndnsd.rb.

The [Debian 6 init.d script](docs/debian-6-init-dyndnsd) assumes that dyndnsd.rb is installed into the system ruby (no RVM support) and the config.yaml is at /opt/dyndnsd/config.yaml. Modify to your needs.


### Monitoring

For monitoring dyndnsd.rb uses the [metriks](https://github.com/eric/metriks) framework and exposes several metrics like the number of unauthenticated requests, requests that did (not) update a hostname, etc. By default the most important metrics are shown in the [proctitle](https://github.com/eric/metriks#proc-title-reporter) but you can also configure a [Graphite](https://graphiteapp.org/) backend for central monitoring or the [textfile_reporter](https://github.com/prometheus/node_exporter/#textfile-collector) which outputs Graphite-style metrics that are also compatible with Prometheus to a file.

```yaml
host: "0.0.0.0"
port: 8245 # the DynDNS.com alternative HTTP port
db: "/opt/dyndnsd/db.json"
domain: "dyn.example.org"
# configure the Graphite backend to be used instead of proctitle
graphite:
  host: localhost # defaults for host and port of a carbon server
  port: 2003
  prefix: "my.graphite.metrics.naming.structure.dyndnsd"
# OR configure the textfile reporter instead of Graphite/proctitle
textfile:
  file: /path/to/file.prom
  prefix: "my.graphite.metrics.naming.structure.dyndnsd"
# configure the updater, here we use command_with_bind_zone, params are updater-specific
updater:
  name: "command_with_bind_zone"
  params:
    zone_file: "dyn.zone"
    command: "echo 'Hello'"
    ttl: "5m"
    dns: "dns.example.org."
    email_addr: "admin.example.org."
# user database with hostnames a user is allowed to update
users:
  # 'foo' is username, 'secret' the password
  foo:
    password: "secret"
    hosts:
      - foo.example.org
      - bar.example.org
  test:
    password: "ihavenohosts"
```


### Tracing (experimental)

For tracing, dyndnsd.rb is instrumented using the [OpenTracing](http://opentracing.io/) framework and will emit span tracing data for the most important operations happening during the request/response cycle. Using a middleware for Rack allows handling incoming OpenTracing span information properly.

Currently only one OpenTracing-compatible tracer implementation named [CNCF Jaeger](https://github.com/jaegertracing/jaeger) can be configured to use with dyndnsd.rb.

```yaml
host: "0.0.0.0"
port: 8245 # the DynDNS.com alternative HTTP port
db: "/opt/dyndnsd/db.json"
domain: "dyn.example.org"
# enable and configure tracing using the (currently only) tracer jaeger
tracing:
  trust_incoming_span: false # default value, change to accept incoming OpenTracing spans as parents
  jaeger:
    host: 127.0.0.1 # defaults for host and port of local jaeger-agent
    port: 6831
    service_name: "my.dyndnsd.identifier"
# configure the updater, here we use command_with_bind_zone, params are updater-specific
updater:
  name: "command_with_bind_zone"
  params:
    zone_file: "dyn.zone"
    command: "echo 'Hello'"
    ttl: "5m"
    dns: "dns.example.org."
    email_addr: "admin.example.org."
# user database with hostnames a user is allowed to update
users:
  # 'foo' is username, 'secret' the password
  foo:
    password: "secret"
    hosts:
      - foo.example.org
      - bar.example.org
  test:
    password: "ihavenohosts"
```


## License

dyndnsd.rb is licensed under the Apache License, Version 2.0. See LICENSE for more information.
