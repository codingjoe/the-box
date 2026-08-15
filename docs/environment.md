# Environment

[12-factor] apps are designed to be portable and resilient by strictly separating configuration from code. This approach allows applications to adapt seamlessly across different environments, such as development, staging, and production.

Your environment variables are stored on GitHub in your repository.

## Default runtime variables

The default variables are set:

- `HOSTNAME`: The hostname of your application.
- `DATABASE_URL`: The URL for your database connection.
- `REDIS_URL`: The URL for your Redis instance.
- `EMAIL_URL`: The URL to your SMTP relay instance.

## External database access

PostgreSQL is optional. When the postgres service is included in the composition, it is exposed through the Caddy reverse proxy on port `443` with TLS termination and a signed certificate. The L4 listener routes PostgreSQL traffic by SNI and ALPN. Connect from outside the Docker host with:

```bash
psql "postgresql://postgres:${POSTGRES_PASSWORD}@pg.${HOSTNAME}:443/postgres?sslmode=require"
```

The proxy accepts both classic `SSLRequest` negotiation and plaintext connections.

Redis is optional. When the redis service is included in the composition, it is exposed through the Caddy reverse proxy on port `443` with TLS termination. Connect from outside the Docker host with:

```bash
redis-cli --tls -h redis.${HOSTNAME} -p 443 --sni redis.${HOSTNAME} -a ${REDIS_PASSWORD}
```

## Managing variables

GitHub can store multiple environments for a single repository. Each environment can have its own set of variables and secrets. You can create environments such as `development`, `staging`, and `production` to manage different configurations for each stage of your application lifecycle.

If your workflow targets a specific environment, GitHub Actions will automatically load the corresponding variables and secrets for that environment during the workflow run.

> [!IMPORTANT]
> GitHub will inherit secrets from the repository level to the environment level, but not the other way around. Be cautious when naming secrets at both levels to avoid unintentional overrides. Environment-level secrets will take precedence over repository-level secrets with the same name.

### Variables

Variables are stored in plain text and retrievable.

```bash
# With body
gh variable set VARIABLE_NAME --env production --body "variable_value"
# from file
gh variable set VARIABLE_NAME --env production <path/to/file
```

### Secrets

Secrets are securely stored and non-retrievable.

```bash
# With body
gh secret set SECRET_NAME --env production --body "variable_value"
# from file
gh secret set SECRET_NAME --env production <path/to/file
# create a random secret
python -c "import secrets; print(secrets.token_urlsafe())" | gh secret set SECRET_NAME --env production
```

[12-factor]: https://12factor.net/
