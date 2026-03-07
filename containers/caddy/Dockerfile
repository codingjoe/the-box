FROM caddy:2.11.2-builder-alpine AS builder

RUN xcaddy build \
    --with github.com/lucaslorentz/caddy-docker-proxy/v2 \
    --with github.com/caddyserver/cache-handler

RUN echo $PATH
RUN which caddy-proxy

FROM caddy:2.11.2-alpine
LABEL title="Caddy reverse proxy"
LABEL license="BSD-2-Clause"
LABEL url="https://github.com/codingjoe/the-box"

COPY --from=builder /usr/bin/caddy /usr/bin/caddy
COPY Caddyfile /etc/caddy/Caddyfile


ENTRYPOINT ["/bin/caddy"]

CMD ["docker-proxy", "--caddyfile-path", "/etc/caddy/Caddyfile"]
