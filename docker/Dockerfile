FROM alpine:3.13.2

EXPOSE 5353 8080

ARG DYNDNSD_VERSION=3.3.1

RUN apk --no-cache add openssl ca-certificates && \
    apk --no-cache add ruby ruby-etc ruby-io-console ruby-json ruby-webrick && \
    apk --no-cache add --virtual .build-deps linux-headers ruby-dev build-base tzdata && \
    gem install --no-document dyndnsd -v ${DYNDNSD_VERSION} && \
    # set timezone to Berlin
    cp /usr/share/zoneinfo/Europe/Berlin /etc/localtime && \
    apk del .build-deps

ENTRYPOINT ["dyndnsd", "/etc/dyndnsd/config.yml"]
