# Docker Rollout

Install the [docker-rollout](https://github.com/wowu/docker-rollout) Docker CLI plugin
for zero downtime deployments with Docker Compose.

## Usage

```yaml
  - name: Install docker-rollout plugin
    uses: codingjoe/the-box/actions/rollout@main
    with:
      version: v0.14 # Optional, specify the version to install (default is latest)
```
