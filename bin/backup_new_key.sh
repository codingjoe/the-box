#!/usr/bin/env bash
# Usage: curl -fsSL https://the-box.sh/backup_new_key.sh | bash
# Generate a new PGP backup encryption key pair for this repository.

set -euo pipefail

sluggify() {
    echo "$1" | iconv -t "ascii//TRANSLIT" | sed -r "s/[~\^]+//g" | sed -r "s/[^a-zA-Z0-9]+/-/g" | sed -r "s/^-+\|-+$//g" | tr '[:upper:]' '[:lower:]'
}

success_msg='\033[1;32m'
error='\033[0;31m'
fin='\033[0m'

for cmd in gpg gh; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
        echo -e "${error}${cmd} is not installed. Install it and try again.${fin}"
        exit 1
    fi
done

gh_owner=$(gh repo view --json owner -q '.owner.login')
project_name=$(sluggify "$(gh repo view --json name -q '.name')")
gpg_email="backup@${gh_owner}-${project_name}"

mkdir -p .box

gpg --batch --full-generate-key <<EOF
%no-protection
Key-Type: RSA
Key-Length: 4096
Name-Real: The Box Backup
Name-Email: ${gpg_email}
Expire-Date: 0
%commit
EOF

gpg --export --armor "$gpg_email" > .box/backup.pub
gpg --export-secret-keys --armor "$gpg_email" > .box/backup-private.key

if [ ! -s .box/backup.pub ]; then
    echo -e "${error}The public key file is empty. The key generation failed.${fin}"
    exit 1
fi

git add .box/backup.pub
git commit -m "Add backup encryption public key"

echo -e "${success_msg}SUCCESS${fin}"
echo -e "${error}WARNING:${fin} Save .box/backup-private.key in a safe place."
echo "You need it to decrypt and restore backups. It is not stored on GitHub."
echo "To import on another machine: gpg --import <path-to>/backup-private.key"
echo "Push the commit to GitHub: git push"
