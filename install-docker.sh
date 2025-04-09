#!/bin/bash

# Check for root privileges
if [[ $EUID -ne 0 ]]; then
  echo "This script requires root privileges. Please run with sudo or as root."
  exit 1
fi

# Detect the current distribution
if [[ -f /etc/os-release ]]; then
  . /etc/os-release
else
  echo "Unable to detect distribution. The /etc/os-release file does not exist."
  exit 1
fi

echo "You are using distribution: $NAME"

# Function to check for command errors
check_error() {
  if [[ $? -ne 0 ]]; then
    echo "Error: $1 failed. Exiting script."
    exit 1
  fi
}

# Function to enable and start Docker
enable_docker() {
  systemctl start docker
  check_error "Starting Docker"
  systemctl enable docker
  check_error "Enabling Docker to start on boot"
}

# Check if Docker is already installed
if command -v docker &>/dev/null; then
  echo "Docker is already installed. Skipping installation."
else
  case "$ID" in
    ubuntu|debian)
      echo "Installing Docker for Debian/Ubuntu..."
      apt update -y
      check_error "Updating apt packages"
      apt install -y apt-transport-https ca-certificates curl software-properties-common
      check_error "Installing prerequisite packages"
      curl -fsSL "https://download.docker.com/linux/$ID/gpg" | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
      check_error "Adding Docker GPG key"
      echo "deb [signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/$ID $(lsb_release -cs) stable" \
        | tee /etc/apt/sources.list.d/docker.list > /dev/null
      apt update -y
      check_error "Updating apt after adding repository"
      apt install -y docker-ce docker-ce-cli containerd.io
      check_error "Installing Docker"
      enable_docker
    ;;

    centos|rhel|rocky)
      echo "Installing Docker for CentOS/RHEL/Rocky..."
      yum remove -y docker docker-client docker-client-latest docker-common docker-latest docker-latest-logrotate docker-logrotate docker-engine || true
      yum install -y yum-utils
      check_error "Installing yum-utils"
      yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
      check_error "Adding Docker repository"
      yum install -y docker-ce docker-ce-cli containerd.io
      check_error "Installing Docker"
      enable_docker
    ;;

    fedora)
      echo "Installing Docker for Fedora..."
      dnf -y install dnf-plugins-core
      check_error "Installing dnf-plugins-core"
      dnf config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo
      check_error "Adding Docker repository"
      dnf install -y docker-ce docker-ce-cli containerd.io
      check_error "Installing Docker"
      enable_docker
    ;;

    *)
      echo "Distribution '$ID' is not supported by this script."
      exit 1
    ;;
  esac
fi

# Install Docker Compose if not already installed
if command -v docker-compose &>/dev/null; then
  echo "Docker Compose is already installed. Skipping installation."
else
  echo "Installing the latest version of Docker Compose..."
  curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" \
    -o /usr/local/bin/docker-compose
  check_error "Downloading Docker Compose"
  chmod +x /usr/local/bin/docker-compose
  check_error "Setting permissions for Docker Compose"
fi

# Display installed versions
echo "Installed versions:"
docker -v
docker-compose -v