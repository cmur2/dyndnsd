FROM alpine:3.12

EXPOSE 5353 8080

ENV VERSION=3.0.0

RUN apk --no-cache add openssl ca-certificates && \
    apk --no-cache add ruby ruby-etc ruby-io-console ruby-json ruby-webrick && \
    apk --no-cache add --virtual .build-deps ruby-dev build-base tzdata && \
    gem install --no-document dyndnsd -v ${VERSION} && \
    # set timezone to Berlin
    cp /usr/share/zoneinfo/Europe/Berlin /etc/localtime && \
    apk del .build-deps

ENTRYPOINT ["dyndnsd", "/etc/dyndnsd/config.yml"]
