FROM alpine:3.13.4

EXPOSE 5353 8080

ARG DYNDNSD_VERSION=3.4.0

RUN apk --no-cache add openssl ca-certificates && \
    apk --no-cache add ruby ruby-etc ruby-io-console ruby-json ruby-webrick && \
    apk --no-cache add --virtual .build-deps linux-headers ruby-dev build-base tzdata && \
    gem install --no-document dyndnsd -v ${DYNDNSD_VERSION} && \
    # set timezone to Berlin
    cp /usr/share/zoneinfo/Europe/Berlin /etc/localtime && \
    apk del .build-deps

# Follow the principle of least privilege: run as unprivileged user.
# Running as non-root enables running this image in platforms like OpenShift
# that do not allow images running as root.
# User ID 65534 is usually user 'nobody'.
USER 65534

ENTRYPOINT ["dyndnsd", "/etc/dyndnsd/config.yml"]
