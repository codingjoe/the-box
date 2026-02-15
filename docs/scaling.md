# Scaling

The Box allows you to start small and scale your applications as they grow in popularity. There are multiple ways to progressively scale your applications depending on your needs without breaking the bank.

## Scaling services

The Box defaults to a highly available web server setup with a minimum of two web servers behind a load balancer. This allows your application to handle more traffic and provides redundancy in case one of the web servers goes down.

You can easily add more web servers to your application by simply adding more containers to the `web` service in your `compose.yml` file.

```yaml
services:
  web:
    deploy:
      replicas: 3  # Increase the number of replicas
```

You may also scale ad-hoc using the Docker CLI:

```bash
docker service scale web=5  # Scale to 5 replicas
```

### Resource management

You can also limit the resources used by each service in your [`containers/web/compose.yml`](../containers/compose.web.yml) file. This allows you to control the amount of CPU and memory used by each service.

```yaml
services:
  web:
    memswap_limit: 1g  # Limit total memory + swap to 1GB
    deploy:
      resources:
        limits:
          cpus: '0.50'      # Limit to 50% of a CPU
          memory: 512M      # Limit to 512MB of RAM
        reservations:
          cpus: '0.25'      # Reserve 25% of a CPU
          memory: 256M      # Reserve 256MB of RAM
```

> [!IMPORTANT]
> Setting resource limits is important to prevent a single service from consuming all available resources on the server, which could lead to performance degradation or crashes. You MUST always set `memswap_limit` to prevent services from using swap space. Swapping will prevent OOM (out of memory) restarts.

## Long term growth strategies

### Scaling Vertically

Most datacenters will offer VPS or dedicated servers in a variety of sizes and the ability to upgrade an existing server to a larger size. This is known as vertical scaling or scaling up.

This will probably be the easiest way to scale your application, especially if you are just starting out. Simply upgrade your server to a larger size and The Box will automatically take advantage of the additional resources.

### Scaling Horizontally

When your application outgrows the resources of a single server, you can just add a second one. Docker [Swarm mode](https://docs.docker.com/engine/swarm/) is low effort way to just add more servers to your PaaS. Setup takes minutes and The Box will automatically distribute your applications across the available servers.

### Hyperscale

Congratulations, you made it! Your application is so popular that you need to scale beyond a few servers.
Luckily, you are not locked to any specific cloud provider or technology. Since your entire application is already containerized, you can easily migrate to a Kubernetes based solution or a managed container service like AWS ECS, Google GKE or Azure AKS.
