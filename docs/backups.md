# Backups

## Database backups

PostgreSQL backups are captured daily using [pg_dump](https://www.postgresql.org/docs/current/app-pgdump.html) and stored as repository artifacts in GitHub Actions.

### Durability

By default, GitHub retains workflow artifacts for 90 days. You can [adjust the retention period](https://docs.github.com/en/organizations/managing-organization-settings/configuring-the-retention-period-for-github-actions-artifacts-and-logs-in-your-organization) up to a maximum of 400 days.

Importantly, artifacts are stored independently of your application server, ensuring that backups remain safe even if your server fails.

The backup frequency may be altered in the [back action](../actions/backup/action.yml) file. Here you may also configure additional backup targets, such as cloud storage providers.

### Restoration

To restore a backup, download the desired artifact from the GitHub Actions workflow run history. The artifact will be a compressed file containing the SQL dump.

You can restore the database using the built-in database scripts:

```bash
bin/backup_download.sh
bin/backup_restore.sh
```

> [!NOTE]
> Backups are stored in PostgreSQL's [custom format](https://www.postgresql.org/docs/current/app-pgdump.html) which is compressed and allows for more flexible restoration options.

### Privacy

With backups being stored on GitHub, it's crucial to consider the sensitivity of your data. Ensure that your repository is private to prevent unauthorized access to your backups. Additionally, consider encrypting your database dumps before uploading them as artifacts for an added layer of security.

> [!IMPORTANT]
> If you are serving customers in the EU, ensure that you add GitHub as a data processor in your privacy policy to comply with GDPR regulations.
