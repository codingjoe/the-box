# The Box - Deployment Action

Deploy an application to a server using Docker Compose over SSH.
The action pulls the pre-built images that the CI workflow published to the GitHub Container Registry.
The server never builds images itself, which keeps the load on small servers low.
Traffic facing services roll out without downtime, others are recreated gracefully.

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

Traffic facing services are updated with [docker-rollout](https://github.com/wowu/docker-rollout).
It scales each service to twice its replicas, waits for the new containers to become healthy, and removes the old ones only then.
Unhealthy new containers roll back and fail the deployment.

Most apps need no configuration: `web` is rolled out by default.
Apps with multiple traffic facing services set `rollout-services`:

```yaml
  - uses: codingjoe/the-box/actions/deploy@main
    with:
      rollout-services: web mta msa
```

All other services are recreated gracefully: Docker Compose stops them, honoring `stop_grace_period`, then starts new ones.
Workers drain on `SIGTERM`, one-shot jobs like migrations run before the rollout starts.
Gate rollout services on them with a `service_completed_successfully` dependency, as in the [relay](https://github.com/codingjoe/relay) example.

Rollout services must not publish host ports or define a `container_name`, since old and new containers run in parallel.
Route TCP through the Caddy proxy instead, like [relay](https://github.com/codingjoe/relay) does for SMTP with layer 4 labels.

Give rollout services a healthcheck.
Without one, the deployment waits a fixed 10 seconds.
Set `rollout-timeout` above the healthcheck's `start_period` plus `interval` times `retries`, the default of 120 seconds fits most apps.
