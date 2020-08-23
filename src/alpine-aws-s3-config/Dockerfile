FROM infrablocks/alpine-aws:0.12.0

RUN apk -v --no-cache add \
      bash \
      curl \
      dumb-init \
      sed

COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh

RUN ["chmod", "+x", "/usr/local/bin/docker-entrypoint.sh"]

ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
