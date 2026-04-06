FROM caddy:2.11.2-builder-alpine AS builder


RUN --mount=type=cache,target=/go/pkg/mod \
    --mount=type=cache,target=/root/.cache/go-build \
    --mount=type=cache,target=/root/.cache/go-build \
    xcaddy build \
    --with github.com/lucaslorentz/caddy-docker-proxy/v2 \
    --with github.com/caddyserver/cache-handler


FROM caddy:2.11.2-alpine
LABEL title="Caddy reverse proxy"
LABEL license="BSD-2-Clause"
LABEL url="https://github.com/codingjoe/the-box"

COPY --from=builder /usr/bin/caddy /usr/bin/caddy
COPY Caddyfile /etc/caddy/Caddyfile

ENTRYPOINT ["/usr/bin/caddy"]
CMD ["docker-proxy", "--caddyfile-path", "/etc/caddy/Caddyfile"]
