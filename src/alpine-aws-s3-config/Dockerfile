FROM infrablocks/alpine-aws:0.15.0

RUN apk \
      --verbose \
      --no-cache \
      add \
          bash \
          curl \
          dumb-init

COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh

RUN ["chmod", "+x", "/usr/local/bin/docker-entrypoint.sh"]

ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
