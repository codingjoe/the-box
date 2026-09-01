# Deployment

Deploying your application with The Box is a streamlined process that involves running an installation script and leveraging GitHub Actions for continuous deployment.

## Initial Setup

The primary setup is handled by an interactive script. To start the installation wizard, run the following command from the root of the repository:

```bash
./bin/install.sh
```

This script will guide you through the following steps:

1. **Domain Configuration**: You will be prompted to enter your domain name.
1. **Server Access**: The script will verify SSH access to your server.
1. **Repository Configuration**: The script will set up the necessary GitHub repository secrets and variables to enable automated deployments. These include:
   - `SSH_HOSTNAME`: Your server's hostname or IP address.
   - `SSH_PRIVATE_KEY`: A private SSH key for accessing the server.
   - `SSH_KNOWN_HOSTS`: Your server's SSH host key.

## Continuous Deployment

Once the initial setup is complete, your application will be automatically deployed whenever you push changes to the `main` branch.

### Publish images

Add the workflow template from [`workflows/ci.yml`](https://github.com/codingjoe/the-box/blob/main/workflows/ci.yml) to your repository as `.github/workflows/ci.yml`. The workflow builds your image and publishes it to the GitHub Container Registry as `ghcr.io/OWNER/REPO:sha-GIT-SHA` on every push to the `main` branch. Pull requests build the image to validate it, without publishing it. Add the test jobs for your application to the same workflow.

If your compose build section sets a build target or build args, set the same values on the `docker/build-push-action` step, so that the published image matches your local builds.

> [!IMPORTANT]
> Container packages on the GitHub Container Registry are private by default. Make your image public in the package settings, so that your server can pull it without authentication.

Reference the published image in your `compose.ENVIRONMENT.yml` file, instead of a build section:

```yaml
services:
  web:
    image: ghcr.io/OWNER/REPO:${IMAGE_TAG:-local}
    pull_policy: always
```

The `local` default keeps local development working, where the build section defines the image.
The `pull_policy: always` makes the server pull the published image, even without the deploy action.
The deploy action sets the `IMAGE_TAG` environment variable to `sha-GIT-SHA` of the exact commit that your CI workflow built. The immutable SHA tag makes sure that your server always deploys the commit that passed your tests. A deployment without the variable fails loudly when it tries to pull the `local` tag, instead of silently deploying a stale image. Services that extend `web` inherit the image, so all replicas pull the same image once.

For local development, set `pull_policy: build` in your `compose.yml` file to always build the image locally:

```yaml
services:
  web:
    pull_policy: build
    build:
      target: development
```

### Deploy the application

The deployment is handled by the [`actions/deploy/action.yml`](https://github.com/codingjoe/the-box/blob/main/actions/deploy/action.yml) GitHub Actions workflow. Add the workflow template from [`workflows/deploy.yml`](https://github.com/codingjoe/the-box/blob/main/workflows/deploy.yml) to your repository as `.github/workflows/deploy.yml`.

The deployment workflow performs the following steps:

1. **Trigger**: The workflow is triggered by a push to the `main` branch (after the `ci` workflow succeeds) or can be triggered manually.
1. **Environment Setup**: It sets up an SSH connection to your production server using the configured secrets.
1. **Remote Deployment**: It establishes a remote Docker context to your server.
1. **Application Start**: It pulls the published images and starts the application containers. Traffic facing services are rolled out without downtime, all other services are recreated gracefully. Your server never builds images itself, which keeps the load on your server low.

Your application will be served via a Caddy reverse proxy, which also handles automatic SSL certificate provisioning.

### Zero-downtime deployments

The deploy action updates traffic facing services without downtime, using [docker-rollout](https://github.com/wowu/docker-rollout).
It scales each service to twice its replica count, waits for the new containers to become healthy, and removes the old containers only then.
If the new containers don't become healthy in time, the deployment is rolled back and fails.
The Caddy proxy picks up the new containers automatically and stops routing to the old ones, so users never see an error.

Apps with a single traffic service need no configuration.
The deploy action rolls out the `web` service by default.
Apps with multiple traffic facing services, like [relay](https://github.com/codingjoe/relay), list them in the `rollout-services` input:

```yaml
  - uses: codingjoe/the-box/actions/deploy@main
    with:
      rollout-services: web mta msa     # rolled out one after another
```

All other services are recreated the classic way.
Docker Compose stops the old containers, honoring `stop_grace_period`, and starts new ones.
This drains workers gracefully, while they finish their current job.
One-shot services, like database migrations, also run in this phase, before the rollout starts.
To make sure a one-shot service runs before the new replicas start, make it a `service_completed_successfully` dependency of the rollout service, as in the [relay](https://github.com/codingjoe/relay) example.

Rollout services must not publish host ports or define a `container_name`.
docker-rollout runs old and new containers in parallel, so ports and names must be free.
Route TCP traffic through the Caddy proxy instead.
[relay](https://github.com/codingjoe/relay) does this for SMTP, using layer 4 proxy labels.

Rollout services should define a healthcheck.
With a healthcheck, the deployment waits until the new containers are actually healthy and rolls back otherwise.
Without a healthcheck, it waits a fixed 10 seconds.
Set `rollout-timeout` to more than the healthcheck's `start_period` plus `interval` times `retries`.
The default of 120 seconds fits most apps.

To not drop requests that a stopping container is still processing, you can drain the old containers, using the `docker-rollout.pre-stop-hook` label.
The hook must fail the container's healthcheck, so the proxy stops routing to it, before it is stopped.
See the [docker-rollout docs](https://docker-rollout.wowu.dev/container-draining) for details.
