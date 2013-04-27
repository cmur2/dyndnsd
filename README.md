# dyndnsd.rb

[![Build Status](https://travis-ci.org/cmur2/dyndnsd.png)](https://travis-ci.org/cmur2/dyndnsd)

A small, lightweight and extensible DynDNS server written with Ruby and Rack.

## Description

dyndnsd.rb is aimed to implement a small [DynDNS-compliant](http://dyn.com/support/developers/api/) server in Ruby. It has an integrated user and hostname database in it's configuration file that is used for authentication and authorization. Besides talking the DynDNS protocol it is able to invoke an so-called *updater*, a small Ruby module that takes care of supplying the current host => ip mapping to a DNS server.

The is currently one updater shipped with dyndnsd.rb `command_with_bind_zone` that writes out a zone file in BIND syntax onto the current system and invokes a user-supplied command afterwards that is assumed to trigger the DNS server (not necessarily BIND since it's zone files are read by other DNS servers too) to reload it's zone configuration.

## General Usage

Install the gem:

	gem install dyndnsd

Create a configuration file in YAML format somewhere:

```yaml
# listen address and port
host: "0.0.0.0"
port: "80"
# logfile is optional, logs to STDOUT else
logfile: "dyndnsd.log"
# interal database file
db: "db.json"
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
  foo:
    password: "secret"
    hosts:
      - foo.example.org
      - bar.example.org
```

Run dyndnsd.rb by:

	dyndnsd /path/to/config.yaml

## Using dyndnsd.rb with [NSD](https://www.nlnetlabs.nl/nsd/)

NSD is a nice opensource, authoritative-only DNS server that reads BIND-style zone files (and converts them into it's own database) and has a simple config file.

A feature NSD is lacking is the [Dynamic DNS update](https://tools.ietf.org/html/rfc2136) functionality BIND offers but one can fake it using the following dyndnsd.rb config:

```yaml
host: "0.0.0.0"
port: "8245" # the DynDNS.com alternative HTTP port
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
    additional_zone_content: "@ IN A 1.2.3.4"
users:
  foo:
    password: "secret"
    hosts:
      - foo.example.org  
```

## License

dyndnsd.rb is licensed under the Apache License, Version 2.0. See LICENSE for more information.
