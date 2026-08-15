# The Box - PostgreSQL Backup Action

Capture an encrypted backup of the PostgreSQL database and upload it as a GitHub Actions artifact.

Backups are encrypted at rest using [age](https://github.com/FiloSottile/age) asymmetric encryption. The public key lives in the repository at `keys/backup.pub`; the private key stays in GitHub secrets.

## Key Generation

Generate an age key pair and configure GitHub:

```sh
mkdir -p keys
age-keygen -o keys/backup.key 2>/dev/null
awk -F': ' '/public key/{print $2}' keys/backup.key > keys/backup.pub
gh secret set BACKUP_PRIVATE_KEY < keys/backup.key
rm -f keys/backup.key
```

Commit `keys/backup.pub` to the repository. Never commit the private key (`keys/backup.key` is git-ignored).

## Usage

```yaml
  - uses: codingjoe/the-box/actions/backup@main
    with:
      ssh-host: ${{ vars.SSH_HOSTNAME }}
      ssh-known-hosts: ${{ vars.SSH_KNOWN_HOSTS }}
      ssh-private-key: ${{ secrets.SSH_PRIVATE_KEY }}
      dotenv-private-key: ${{ secrets.DOTENV_PRIVATE_KEY_PRODUCTION }}
      environment: ${{ github.environment }}
```

The public key path defaults to `keys/backup.pub`. Override it with the `backup-public-key-path` input.

## Restore

Download the latest encrypted backup and restore it to a local PostgreSQL instance:

```sh
./bin/backup_download.sh
./bin/backup_restore.sh <path-to-private-key> [dump_file] [database_name]
```

You need [age](https://github.com/FiloSottile/age#install) and `pg_restore` installed locally.
