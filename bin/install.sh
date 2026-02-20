#!/usr/bin/env bash

set -euo pipefail

sluggify() {
    # Convert a string to a slug suitable for URLs and filenames
    echo "$1" | iconv -t "ascii//TRANSLIT" | sed -r "s/[~\^]+//g" | sed -r "s/[^a-zA-Z0-9]+/-/g" | sed -r "s/^-+\|-+$//g" | tr '[:upper:]' '[:lower:]'
}

hr () {
    printf '\n%*s\n\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' -
}

headline() {
    # =-sign padded headline to whole column width
    local len=${#1}
    local padding=$(( ( ${COLUMNS:-$(tput cols)} - len - 2 ) / 2 ))
    printf '\n%*s\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' =
    printf '%*s %s %*s\n' "$padding" '' "$1" "$padding" ''
    printf '%*s\n\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' =
}

# Color codes for terminal output
success_msg='\033[1;32m'
action='\033[0;3m'
info='\033[1;34m'
error='\033[0;31m'
fin='\033[0m'

# Test if GitHub CLI is installed
if ! command -v gh >/dev/null 2>&1; then
    echo "GitHub CLI (gh) is not installed. Please install it from https://cli.github.com/ and try again."
    exit 1
fi

# Test if Dotenvx is installed
if ! command -v dotenvx >/dev/null 2>&1; then
    echo "Dotenvx is not installed. Please install it from https://dotenvx.com/ and try again."
    exit 1
fi

# org or user
gh_owner=$(gh repo view --json owner -q '.owner.login')

# =============================================================================
headline "The Box Installation Wizard"

echo "
This script will guide you through the installation of The Box on your server and your GitHub repository.
Before you begin, ensure you have:
- SSH access to your server
- the GitHub CLI (gh) installed and authenticated"
hr

# Domain name
read -erp "Enter your domain name (e.g., example.com): " hostname
project_name=$(sluggify "$(gh repo view --json name -q '.name')")

# SSH username
read -erp "Enter your SSH user name for ${hostname} (default: ${USER})?: " input_ssh_username
if [ -n "$input_ssh_username" ]; then
    ssh_username=$input_ssh_username
else
    ssh_username=$USER
fi

# Verify SSH connection
echo ""
printf "${action}Verifying SSH connection to ${info}%s${fin}... " "${hostname}"
if ! ssh -T "${ssh_username}@${hostname}" "echo -e '${success_msg}SUCCESS!${fin}'"; then
    echo -e "${error}SSH connection to ${hostname} failed. Please ensure you can SSH into the server before proceeding."
    exit 1
fi
echo ""

# GitHub owner
read -erp "Enter your GitHub username or organization name (default: $gh_owner): " input_gh_owner
if [ -n "$input_gh_owner" ]; then
    gh_owner=$input_gh_owner
fi

# Project name
read -erp "Enter your project name (default: ${project_name}): " input_project_name
if [ -n "$input_project_name" ]; then
    project_name=$input_project_name
fi

# =============================================================================
headline "Please confirm the following information:"

echo "Domain: ${hostname}"
echo "SSH User: ${ssh_username}"
echo "Project Name: ${project_name}"
echo "GitHub Owner: ${gh_owner}"
hr
echo "Press any key to start the installation, or Ctrl+C to cancel..."
# shellcheck disable=SC2034
read -r confirm

# =============================================================================
headline "SSH Key Setup"

echo -en "Generating SSH key pair for deployment..."
ssh_key_path="$(mktemp -d)"
ssh-keygen -t ed25519 -C "The Box deployment key" -f "${ssh_key_path}/deploy_key" -N "" > /dev/null
ssh_public_key=$(cat "${ssh_key_path}/deploy_key.pub")
echo -e "${success_msg}SUCCESS${fin}"

# =============================================================================
headline "Setting up remote host"

echo -en "${action}"
# Run remote setup script
ssh -T "${ssh_username}@${hostname}" "sh -s -- '${ssh_public_key}'" < "bin/setup_remote_host.sh"
echo -en "${fin}"
echo -e "${success_msg}Remote host setup completed!${fin}"
echo -en "${action}Creating Docker context for remote host... "
if docker context create "${project_name}" --description "The Box remote host for ${hostname}" --docker "host=ssh://collaborator@${hostname}"; then
    docker context export "${project_name}" collaborator.dockercontext
    echo -e "${success_msg}SUCCESS${fin}"
else
    echo -e "${error}FAILED${fin}"
    echo "Make sure you have Docker installed locally, next you can run:
  docker context create \"${project_name}\" --description \"The Box remote host for ${hostname}\" --docker \"host=ssh://collaborator@${hostname}\"
  "
fi


# =============================================================================
headline "Setting your GitHub environment"

echo -en "${action}"

echo "Configuring repository workflow secrets on GitHub..."
gh variable set SSH_HOSTNAME --body "$hostname"
gh variable set SSH_KNOWN_HOSTS --body "$(ssh-keyscan "${hostname}")"
gh variable set SSH_PUBLIC_KEY < "${ssh_key_path}/deploy_key.pub"
gh secret set SSH_PRIVATE_KEY < "${ssh_key_path}/deploy_key"

echo "Setting up your production environment..."
touch .env.production
dotenvx set HOSTNAME "$hostname" -f .env.production -p
dotenvx set POSTGRES_PASSWORD "$(python -c "import secrets; print(secrets.token_urlsafe())")" -f .env.production
dotenvx set REDIS_PASSWORD "$(python -c "import secrets; print(secrets.token_urlsafe())")" -f .env.production
dotenvx get DOTENV_PRIVATE_KEY_PRODUCTION -f .env.keys | gh secret set DOTENV_PRIVATE_KEY_PRODUCTION

echo "Syncing collaborator SSH keys..."
gh workflow run sync-ssh-keys.yml --ref main

echo "Triggering deployment workflow..."
gh workflow run deploy.yml --ref main

echo -en "${fin}"

# =============================================================================
headline "Setting up your development environment"

mv .env.example .env
cat >> .dtop.yml <<EOL
  - host: ssh://collaborator@${hostname}
    dozzle: https://logs.${hostname}/
EOL

echo "Setup complete! Your project ${project_name} is being deployed to ${hostname}."
