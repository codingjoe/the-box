# Monitoring

Monitoring is a crucial aspect of managing applications deployed on The Box. It allows developers and administrators to keep track of application performance, resource usage, and overall health. The Box provides built-in monitoring tools that offer insights into various metrics, enabling proactive management and troubleshooting.

## Built-in Monitoring Tools

The Box integrates [Dozzle] and [dtop] to provide real-time monitoring and logging capabilities.

Dozzle binds to `127.0.0.1` on the Docker host.
Forward the port to your machine with SSH and open `http://localhost:5000` in your web browser:

```bash
ssh -L 5000:127.0.0.1:8080 collaborator@<your-server>
```

The local port is yours to choose, and so is the destination spelling.
The pinned SSH key permits `127.0.0.1:8080` and `localhost:8080`, exactly as written, so `ssh -L 5000:localhost:8080 collaborator@<your-server>` works too.
Any other destination is refused with `open failed: administratively prohibited`.

SSH access to the server is the only authentication.
Dozzle needs no additional login.

Dozzle has container actions and shell access enabled.
You can start, stop, and restart containers, or open a shell, from the dropdown next to the container stats.
Use these tools with care.

To access via shell, use the following commands:

```bash
dtop
```

The install script creates a `.dtop.yml` configuration file for your project with production and development contexts.

## Automatic Recovery

The Box restarts unhealthy containers with [autoheal].
A container is unhealthy when its healthcheck keeps failing.
Docker does not restart an unhealthy container on its own, because its process still runs.

Autoheal polls the Docker API and restarts every container that reports an unhealthy status.
It monitors all containers on the host, including the containers of all applications.
Add the label `autoheal.monitor.enable=false` to a container to exclude it from automatic recovery.
Add the label `autoheal.restart.enable=false` to keep a container monitored without restarting it.

Autoheal waits up to 10 seconds for a container to stop before it kills it.
Set the `autoheal.stop.timeout` label on a container to change that value, in seconds.

Containers without a healthcheck are never restarted, because Docker reports no health status for them.
Traffic facing services need a healthcheck for the zero-downtime rollout anyway, see [Deployment](deployment.md).

The deploy action pauses automatic recovery for the duration of a rollout.

## Application Monitoring

The Box provides only basic monitoring tools out of the box to help you assess your container health. For more advanced monitoring, logging, and alerting capabilities, consider integrating third-party services such as [Sentry].

## MCP Endpoint

Dozzle exposes a read-only [MCP] endpoint for AI coding assistants at `/api/mcp`.
Forward the port as shown above, then add the server to your MCP client configuration:

```json
{
  "mcpServers": {
    "dozzle": {
      "type": "http",
      "url": "http://127.0.0.1:5000/api/mcp"
    }
  }
}
```

The tools are read-only.
They list containers and hosts, and fetch or search container logs.

[autoheal]: https://github.com/tmknight/docker-autoheal
[dozzle]: https://dozzle.dev/
[dtop]: https://dtop.dev/
[mcp]: https://modelcontextprotocol.io/
[sentry]: https://sentry.io/welcome/
