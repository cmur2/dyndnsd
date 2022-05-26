FROM alpine:3.16.0

EXPOSE 5353 8080

COPY pkg/dyndnsd-*.gem /tmp/dyndnsd.gem

RUN apk --no-cache add openssl ca-certificates && \
    apk --no-cache add ruby ruby-etc ruby-io-console ruby-json ruby-webrick && \
    apk --no-cache add --virtual .build-deps linux-headers ruby-dev build-base tzdata && \
    gem install --no-document /tmp/dyndnsd.gem && \
    rm -rf /usr/lib/ruby/gems/*/cache/ && \
    # set timezone to Berlin
    cp /usr/share/zoneinfo/Europe/Berlin /etc/localtime && \
    apk del .build-deps

# Follow the principle of least privilege: run as unprivileged user.
# Running as non-root enables running this image in platforms like OpenShift
# that do not allow images running as root.
# User ID 65534 is usually user 'nobody'.
USER 65534

ENTRYPOINT ["dyndnsd", "/etc/dyndnsd/config.yml"]
