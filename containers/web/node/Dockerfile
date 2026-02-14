FROM debian:trixie-slim AS build
LABEL title="SMTP Server"
LABEL license="BSD-2-Clause"
LABEL url="https://github.com/codingjoe/the-box"

# Install dependencies
COPY ../../../Aptfile /tmp
RUN cd /tmp && apt-get update && cat Aptfile | xargs apt-get download \
    && mkdir -p /dpkg && \
    for deb in *.deb; do dpkg --extract $deb /dpkg || exit 10; done

RUN apt-get install -y curl git build-essential

ENV N_PREFIX=/opt/nodejs
ENV PATH=$N_PREFIX/bin:$PATH
ARG NODE_ENV=production
ENV NODE_ENV=$NODE_ENV

WORKDIR /app
COPY .nvmrc /app/.nvmrc
RUN curl -fsSL https://raw.githubusercontent.com/tj/n/master/bin/n | bash -s install --cleanup auto
RUN mkdir node_modules # In case there are no dependencies
# Install dependencies based on the preferred package manager
COPY package.json yarn.lock* package-lock.json* pnpm-lock.yaml* .npmrc* ./
RUN  \
  if [ -f yarn.lock ]; then yarn --frozen-lockfile; \
  elif [ -f package-lock.json ]; then npm ci; \
  elif [ -f pnpm-lock.yaml ]; then corepack enable pnpm && pnpm i --frozen-lockfile; \
  else echo "Lockfile not found." && exit 1; \
  fi

FROM gcr.io/distroless/cc:nonroot AS development

# Copy binary dependencies
COPY --from=build /dpkg /

# Copy Node dependencies
COPY --from=build --chown=root:root /opt/nodejs /opt/nodejs
COPY --from=build --chown=root:root /app/node_modules /opt/node_modules

ENV NODE_PATH=/opt/node_modules
ENV PATH="/opt/nodejs/bin:$PATH"

WORKDIR /app

ENTRYPOINT ["node"]

FROM development AS production

COPY . /app
