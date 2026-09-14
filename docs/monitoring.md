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

## PostgreSQL query statistics

The managed PostgreSQL server preloads [pg_stat_statements] and creates the extension when it initializes a new data directory. Query the collected statistics from outside the Box, as described in [environment](environment.md):

```bash
psql "postgresql://postgres:${POSTGRES_PASSWORD}@pg.${HOSTNAME}:443/postgres?sslmode=require" \
    --command "SELECT calls, mean_exec_time, query FROM pg_stat_statements ORDER BY mean_exec_time DESC LIMIT 10"
```

Run `SELECT pg_stat_statements_reset();` to discard the collected statistics.

> [!NOTE]
> Databases created before the extension was added require `CREATE EXTENSION pg_stat_statements;` once.

[dozzle]: https://dozzle.dev/
[dtop]: https://dtop.dev/
[pg_stat_statements]: https://www.postgresql.org/docs/current/pgstatstatements.html
[sentry]: https://sentry.io/welcome/
