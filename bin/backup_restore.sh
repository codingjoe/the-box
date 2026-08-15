#!/usr/bin/env sh

# Restore the PostgreSQL database from an encrypted dump file
# Usage: ./backup_restore.sh [dump_file] [database_name]
# Requires the backup private key in your GPG keyring.
# To import a private key: gpg --import <private-key-file>

set -eu

dump_file="${1:-backup.dump.gpg}"
database_name="${2:-postgres}"

if ! command -v gpg >/dev/null 2>&1; then
    echo "gpg is not installed. Install GnuPG and try again."
    exit 1
fi

if ! command -v pg_restore >/dev/null 2>&1; then
    echo "pg_restore is not installed. Install PostgreSQL client tools and try again."
    exit 1
fi

tmpfile=$(mktemp)
trap 'rm -f "$tmpfile"' EXIT
gpg --batch --yes --decrypt --output "$tmpfile" "$dump_file"
pg_restore "$tmpfile" -d "$database_name" --no-acl --no-owner --no-privileges --disable-triggers
