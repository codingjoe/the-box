# Monitoring

Monitoring is a crucial aspect of managing applications deployed on The Box. It allows developers and administrators to keep track of application performance, resource usage, and overall health. The Box provides built-in monitoring tools that offer insights into various metrics, enabling proactive management and troubleshooting.

## Built-in Monitoring Tools

The Box integrates [Dozzle] and [dtop] to provide real-time monitoring and logging capabilities.

To access the monitoring tools, navigate to the following URLs in your web browser:

- Dozzle: `http://logs.<your-domain>`

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
