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
1. **Application Start**: It uses `docker compose` to pull the published images and start the application containers. Your server never builds images itself, which keeps the load on your server low.

Your application will be served via a Caddy reverse proxy, which also handles automatic SSL certificate provisioning.
