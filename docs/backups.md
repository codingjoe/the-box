# Backups

## Database backups

The Box captures PostgreSQL backups daily using [pg_dump](https://www.postgresql.org/docs/current/app-pgdump.html) and stores them as repository artifacts in GitHub Actions. The Box encrypts each backup with PGP before upload.

### Durability

By default, GitHub retains workflow artifacts for 90 days. You can [adjust the retention period](https://docs.github.com/en/organizations/managing-organization-settings/configuring-the-retention-period-for-github-actions-artifacts-and-logs-in-your-organization) up to a maximum of 400 days.

GitHub stores artifacts independently of your application server. Backups stay safe even if your server fails.

Change the backup frequency in the [backup action](https://github.com/codingjoe/the-box/blob/main/actions/backup/action.yml) file. You can also configure additional backup targets, such as cloud storage providers.

### Encryption

The install script generates a PGP key pair during setup. It stores the public key at `.box/backup.pub` and commits it to your repository. The script writes the private key to `.box/backup-private.key`. Git ignores this file, so it stays on your local machine.

Keep the private key in a safe place. You need it to decrypt and restore backups. GitHub does not store the private key.

To generate a new key pair, run:

```bash
curl -fsSL https://the-box.sh/backup_new_key.sh | bash
```

Use this for key rotation or to set up encryption again. Push the commit to GitHub after the script completes.

### Restoration

To restore a backup, download the artifact from the GitHub Actions workflow run history. The artifact contains an encrypted SQL dump.

Decryption requires the private key in your GPG keyring. Import the private key on the machine where you restore:

```bash
gpg --import <path-to>/backup-private.key
```

Download the latest backup:

```bash
./bin/backup_download.sh
```

Restore the database from the downloaded file:

```bash
./bin/backup_restore.sh [dump_file] [database_name]
```

The script defaults to `backup.dump.gpg` and the `postgres` database.

> [!NOTE]
> The Box stores backups in PostgreSQL [custom format](https://www.postgresql.org/docs/current/app-pgdump.html). This format is compressed and permits flexible restoration.

### Privacy

The Box encrypts backups before upload, so GitHub never receives unencrypted data. Keep your repository private to add another layer of protection. Store the private key outside the repository and outside GitHub.

> [!IMPORTANT]
> If you serve customers in the EU, add GitHub as a data processor in your privacy policy to comply with GDPR.
