FROM caddy:2.10.0-alpine
LABEL title="Caddy reverse proxy"
LABEL license="BSD-2-Clause"
LABEL url="https://github.com/codingjoe/the-box"

ENV HOSTNAME=localhost

RUN caddy add-package github.com/greenpau/caddy-security

COPY ./containers/paas/Caddyfile /etc/caddy/Caddyfile
