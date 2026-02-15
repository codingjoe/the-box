# File Storage

The Box doesn't offer built-in file storage solutions by default.

Secure storage is a complex topic with many considerations. We recommend using specialized third-party services that are designed to handle file storage securely and efficiently. All major cloud providers offer object storage solutions (compatible with AWS S3) that can be easily integrated into your application.

> [!IMPORTANT]
> Web containers in The Box are designed to be stateless, meaning that any files stored locally within the container will be lost if the container is restarted or redeployed. Therefore, it's crucial to use external storage solutions for any files that need to persist beyond the lifecycle of a single container instance.

## Local storage (not recommended)

If you still want to use local storage for development or testing purposes, you can mount a volume to your web container by modifying the `volumes` section in the [`containers/web/compose.yml`](../containers/compose.web.yml) file.

```yaml
services:
  web:
    volumes:
      - /path/on/host:/path/in/container:z
```

This will mount the specified host directory to the container, allowing files to persist across container restarts. However, be aware that this approach may lead to data loss and performance issues in a production environment.
