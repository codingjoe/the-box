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

Once the initial setup is complete, your application will be automatically deployed whenever you push changes to the `main` branch. This is handled by the [`.github/workflows/deploy.yml`](../containers/actions/deploy/action.yml) GitHub Actions workflow.

The deployment workflow performs the following steps:

1. **Trigger**: The workflow is triggered by a push to the `main` branch (after the `ci` workflow succeeds) or can be triggered manually.
1. **Environment Setup**: It sets up an SSH connection to your production server using the configured secrets.
1. **Remote Deployment**: It establishes a remote Docker context to your server.
1. **Application Start**: It uses `docker compose` to pull the latest images and start the application containers.

Your application will be served via a Caddy reverse proxy, which also handles automatic SSL certificate provisioning.
