FROM caddy:2.10.2-alpine-builder AS builder

RUN xcaddy build \
    --with github.com/lucaslorentz/caddy-docker-proxy/v2

FROM caddy:2.10.2-alpine
LABEL title="Caddy reverse proxy"
LABEL license="BSD-2-Clause"
LABEL url="https://github.com/codingjoe/the-box"

COPY --from=builder /usr/bin/caddy /usr/bin/caddy
CMD ["caddy", "docker-proxy", "--caddyfile-path", "/etc/caddy/Caddyfile"]
