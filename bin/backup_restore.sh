#!/usr/bin/env sh

# Restore the PostgreSQL database from an encrypted dump file
# Usage: ./backup_restore.sh <private_key_file> [dump_file] [database_name]

set -eu

if [ "$#" -lt 1 ]; then
    echo "Usage: $0 <private_key_file> [dump_file] [database_name]"
    exit 1
fi

private_key="$1"
dump_file="${2:-backup.dump.age}"
database_name="${3:-postgres}"

if ! command -v age >/dev/null 2>&1; then
    echo "age is not installed. Install it from https://github.com/FiloSottile/age#install and try again."
    exit 1
fi

if ! command -v pg_restore >/dev/null 2>&1; then
    echo "pg_restore is not installed. Install PostgreSQL client tools and try again."
    exit 1
fi

tmpfile=$(mktemp)
trap 'rm -f "$tmpfile"' EXIT
age -d -i "$private_key" "$dump_file" > "$tmpfile"
pg_restore "$tmpfile" -d "$database_name" --no-acl --no-owner --no-privileges --disable-triggers
