# The Box - PostgreSQL Backup Action

Capture an encrypted backup of the PostgreSQL database and upload it as a GitHub Actions artifact.

Backups are encrypted using [GnuPG](https://gnupg.org/) asymmetric encryption. GPG uses hybrid encryption: a random symmetric session key encrypts the data (fast AES), and the public key encrypts the session key (RSA). The public key lives in the repository at `keys/backup.pub`; the private key stays with the person who set up The Box — it is never stored on GitHub.

## Key Generation

The install script (`bin/install.sh`) generates the key pair automatically. To generate one manually:

```sh
mkdir -p keys
gpg --batch --full-generate-key <<EOF
%no-protection
Key-Type: RSA
Key-Length: 4096
Name-Real: The Box Backup
Name-Email: backup@the-box.local
Expire-Date: 0
%commit
EOF
gpg --export --armor backup@the-box.local > keys/backup.pub
gpg --export-secret-keys --armor backup@the-box.local > keys/backup-private.key
```

Commit `keys/backup.pub` to the repository. Save `keys/backup-private.key` somewhere safe — it is git-ignored and never stored on GitHub. You need it to decrypt and restore backups.

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
./bin/backup_restore.sh [dump_file] [database_name]
```

The private key must be in your GPG keyring. To import it on a new machine:

```sh
gpg --import <path-to>/backup-private.key
```

You need `gpg` and `pg_restore` installed locally.
