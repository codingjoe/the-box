# Monitoring

Monitoring is a crucial aspect of managing applications deployed on The Box. It allows developers and administrators to keep track of application performance, resource usage, and overall health. The Box provides built-in monitoring tools that offer insights into various metrics, enabling proactive management and troubleshooting.

## Built-in Monitoring Tools

The Box integrates [Dozzle] and [dtop] to provide real-time monitoring and logging capabilities.

Dozzle binds to `127.0.0.1` on the Docker host.
Forward the port to your machine with SSH and open `http://localhost:8080` in your web browser:

```bash
ssh -L 8080:127.0.0.1:8080 <your-server>
```

SSH access to the server is the only authentication.
Dozzle needs no additional login.

To access via shell, use the following commands:

```bash
dtop
```

The install script creates a `.dtop.yml` configuration file for your project with production and development contexts.

## Application Monitoring

The Box provides only basic monitoring tools out of the box to help you assess your container health. For more advanced monitoring, logging, and alerting capabilities, consider integrating third-party services such as [Sentry].

[dozzle]: https://dozzle.dev/
[dtop]: https://dtop.dev/
[sentry]: https://sentry.io/welcome/
