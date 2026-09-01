# The Box - Deployment Action

Deploy an application to a server using Docker Compose over SSH.
The action pulls the pre-built images that the CI workflow published to the GitHub Container Registry.
The server never builds images itself, which keeps the load on small servers low.
The deploy action updates traffic facing services without downtime. It recreates all other services.

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

The deploy action updates traffic facing services with [docker-rollout](https://github.com/wowu/docker-rollout).
It scales each service to twice its replicas.
Then it waits for the new containers to become healthy.
After that, it removes the old containers.
If a healthcheck fails, docker-rollout stops the new containers and the deployment fails.

Most apps need no configuration.
The deploy action uses `web` as the default rollout service.
Apps with multiple traffic facing services set `rollout-services`:

```yaml
  - uses: codingjoe/the-box/actions/deploy@main
    with:
      rollout-services: web mta msa
```

The deploy action recreates all other services.
Docker Compose honors `stop_grace_period` when it stops a service, so workers can drain.
One-shot services, like database migrations, run before the rollout starts new replicas.
The rollout service must depend on the one-shot service with `service_completed_successfully`, as in the [relay](https://github.com/codingjoe/relay) example.

Rollout services must not publish host ports or define a `container_name`, because old and new containers run in parallel.
TCP traffic must use the Caddy proxy.
[relay](https://github.com/codingjoe/relay) uses layer 4 labels for SMTP.

Rollout services must define a healthcheck.
Then the deployment waits until the new containers are healthy.
Without a healthcheck, the deployment waits a fixed 10 seconds.
The `rollout-timeout` value must be more than the healthcheck `start_period` plus `interval` times `retries`.
The default of 120 seconds fits most apps.
