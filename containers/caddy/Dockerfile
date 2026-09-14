FROM caddy:2.11.4-builder-alpine AS builder


RUN --mount=type=cache,target=/go/pkg/mod \
    --mount=type=cache,target=/root/.cache/go-build \
    xcaddy build \
    --with github.com/lucaslorentz/caddy-docker-proxy/v2 \
    --with github.com/caddyserver/cache-handler \
    --with github.com/darkweak/storages/redis/caddy \
    --with github.com/mholt/caddy-l4 \
    --with github.com/ueffel/caddy-brotli


FROM caddy:2.11.4-alpine
LABEL org.opencontainers.image.title="the-box-caddy"
LABEL org.opencontainers.image.description="Production ready PaaS you can on a RaspberryPi"
LABEL org.opencontainers.image.url="https://github.com/codingjoe/the-box"
LABEL org.opencontainers.image.source="https://github.com/codingjoe/the-box"
LABEL org.opencontainers.image.licenses="BSD-2-Clause"

COPY --from=builder /usr/bin/caddy /usr/bin/caddy
COPY Caddyfile /etc/caddy/Caddyfile

ENTRYPOINT ["/usr/bin/caddy"]
CMD ["docker-proxy", "--caddyfile-path", "/etc/caddy/Caddyfile"]
