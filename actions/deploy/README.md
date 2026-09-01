# The Box - Deployment Action

Deploy an application to a server using Docker Compose over SSH.
The action pulls the pre-built images that the CI workflow published to the GitHub Container Registry.
The server never builds images itself, which keeps the load on small servers low.
Traffic facing services are updated without downtime, all other services are recreated gracefully.

## Usage

Add the workflow templates to your repository:

- [`workflows/ci.yml`](https://github.com/codingjoe/the-box/blob/main/workflows/ci.yml) as `.github/workflows/ci.yml` — builds and publishes your image
- [`workflows/deploy.yml`](https://github.com/codingjoe/the-box/blob/main/workflows/deploy.yml) as `.github/workflows/deploy.yml` — deploys the published image

The CI workflow publishes your image as `ghcr.io/OWNER/REPO:sha-GIT-SHA`.
Reference the image in your `compose.ENVIRONMENT.yml` file:

```yaml
services:
  web:
    image: ghcr.io/OWNER/REPO:${IMAGE_TAG:-local}
    pull_policy: always
```

The `local` default keeps local development working, where the build section defines the image.
The `pull_policy: always` makes the server pull the published image, even without the deploy action.
The deploy action sets the `IMAGE_TAG` environment variable to `sha-GIT-SHA` of the exact commit that the CI workflow built.
The immutable SHA tag makes sure the server deploys the commit that passed your tests.
A missing tag fails the deployment loudly, instead of silently deploying a stale image.

For local development, set `pull_policy: build` in your `compose.yml` file to always build the image locally:

```yaml
services:
  web:
    pull_policy: build
    build:
      target: development
```

## Requirements

- The CI workflow needs the `packages: write` permission to publish the image.
  The workflow template already grants it.
- Images on the GitHub Container Registry are private by default.
  Make your image public in the package settings, so that your server can pull it without authentication.
  Alternatively, log in to ghcr.io on your server to pull private images.

## Zero-downtime deployments

The deploy action updates the traffic facing services with
[docker-rollout](https://github.com/wowu/docker-rollout).
It scales each service to twice its replica count, waits for the new containers to become
healthy, and only then removes the old containers.
If the new containers don't become healthy in time, the deployment is rolled back and fails.

Apps with a single traffic service need no configuration, the default `web` is rolled out.
Apps with multiple traffic facing services set the `rollout-services` input:

```yaml
      - uses: codingjoe/the-box/actions/deploy@main
        with:
          ...
          rollout-services: web mta msa # rolled out one after another, without downtime
```

All services not listed are recreated the classic way.
Docker Compose stops the old containers gracefully, honoring `stop_grace_period`, and starts
new ones. That is the right behavior for workers, that drain and exit on `SIGTERM`.
One-shot services, like database migrations, also run in this phase, before the rollout
starts new replicas. To run before the new containers, make them a
`service_completed_successfully` dependency of the rollout services, as in the
[relay](https://github.com/codingjoe/relay) example.

Rollout services have two requirements:

- They must not publish host ports or define a `container_name`.
  docker-rollout runs old and new containers in parallel, so ports and names must be free.
  Route traffic through the Caddy proxy instead, like the
  [relay](https://github.com/codingjoe/relay) does with layer 4 proxies for SMTP.
- They should define a healthcheck. With a healthcheck, the deployment waits until the new
  containers are actually healthy and rolls back otherwise. Without a healthcheck, it
  waits a fixed 10 seconds. Set `rollout-timeout` to more than the healthcheck's
  `start_period` plus `interval` times `retries`, the default of 120 seconds fits most apps.
