# Backup

The Box creates daily encrypted PostgreSQL backups and stores them as GitHub Actions artifacts.

## Setting up

The install script (`bin/install.sh`) handles key generation during setup. It creates a GPG key pair unique to your repository and exports:

- **`.box/backup.pub`** — the public key, committed to your repository. The backup workflow uses it to encrypt dumps.
- **`.box/backup-private.key`** — the private key, saved locally. You need it to restore backups. It is git-ignored and never stored on GitHub.

Keep `.box/backup-private.key` safe. Without it, backups cannot be restored.

## Downloading a backup

```sh
./bin/backup_download.sh
```

This downloads the latest successful backup artifact (`backup.dump.gpg`) from GitHub.

## Restoring a backup

The private key must be in your GPG keyring. If you are on a new machine, import it first:

```sh
gpg --import <path-to>/backup-private.key
```

Then restore:

```sh
./bin/backup_restore.sh [dump_file] [database_name]
```

The script defaults to `backup.dump.gpg` and the `postgres` database. The script requires `gpg` and `pg_restore` installed locally.
