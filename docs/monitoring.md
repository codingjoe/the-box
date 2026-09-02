# Monitoring

Monitoring is a crucial aspect of managing applications deployed on The Box. It allows developers and administrators to keep track of application performance, resource usage, and overall health. The Box provides built-in monitoring tools that offer insights into various metrics, enabling proactive management and troubleshooting.

## Built-in Monitoring Tools

The Box integrates [Dozzle] and [dtop] to provide real-time monitoring and logging capabilities.

Dozzle binds to `127.0.0.1` on the Docker host.
Forward the port to your machine with SSH and open `http://localhost:8080` in your web browser:

```bash
ssh -L 8080:127.0.0.1:8080 contributor@<your-server>
```

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
      "url": "http://127.0.0.1:8080/api/mcp"
    }
  }
}
```

The tools are read-only.
They list containers and hosts, and fetch or search container logs.

[dozzle]: https://dozzle.dev/
[dtop]: https://dtop.dev/
[mcp]: https://modelcontextprotocol.io/
[sentry]: https://sentry.io/welcome/
