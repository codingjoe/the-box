#!/usr/bin/env sh

set -eu

# Script to set up a remote host for deployment
# This script is designed to be executed on the remote host (piped via SSH)
# Usage: cat setup_remote_host.sh | ssh user@host sh -s -- <ssh_public_key>

if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <ssh_public_key>"
    exit 1
fi

ssh_public_key=$1

# =============================================================================
# STEP 1: Create users and configure SSH access
# =============================================================================

sudo groupadd docker || true

echo "Setting up github user..."
if ! id github >/dev/null 2>&1; then
    sudo useradd -r -m github -d /home/github -G docker
    echo "Created github user."
else
    echo "github user already exists."
fi

echo "Granting sudo privileges to github user..."
echo "github ALL=(ALL) NOPASSWD:ALL" | sudo tee /etc/sudoers.d/github > /dev/null
sudo chmod 440 /etc/sudoers.d/github

echo "Creating SSH directory for github user..."
sudo mkdir -p /home/github/.ssh
sudo chmod 700 /home/github/.ssh
sudo chown github:github /home/github/.ssh

echo "Setting up SSH key for github user..."
echo "${ssh_public_key}" | sudo tee /home/github/.ssh/authorized_keys > /dev/null
sudo chmod 600 /home/github/.ssh/authorized_keys
sudo chown github:github /home/github/.ssh/authorized_keys
echo "SSH key configured for github user."

echo "Setting up collaborator user..."
if ! id collaborator >/dev/null 2>&1; then
    sudo useradd -r -s /bin/rbash -m -d /home/collaborator collaborator -G docker
    echo "Created collaborator user."
else
    echo "collaborator user already exists."
fi

echo "Creating SSH directory for collaborator user..."
sudo mkdir -p /home/collaborator/.ssh
sudo chmod 700 /home/collaborator/.ssh
sudo touch /home/collaborator/.ssh/authorized_keys
sudo chmod 600 /home/collaborator/.ssh/authorized_keys
sudo chown -R collaborator:collaborator /home/collaborator/.ssh

# =============================================================================
# STEP 2: Install Docker Engine and set up collaborator user
# =============================================================================

echo "Checking if Docker is installed..."
if ! command -v docker >/dev/null 2>&1; then
    echo "Installing Docker..."

    curl -fsSL https://get.docker.com -o /tmp/get-docker.sh
    sudo sh /tmp/get-docker.sh
    sudo systemctl enable docker.service
    sudo systemctl enable containerd.service
    echo "Docker installed successfully."
else
    echo "Docker is already installed."
fi

echo "Remote host setup complete!"
