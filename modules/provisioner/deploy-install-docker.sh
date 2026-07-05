#!/bin/sh
# Upload startup.sh and ensure Docker is installed (OpenSSH local-exec; Unix).

set -e

PRIVATE_KEY_PATH="${PRIVATE_KEY_PATH:-}"
USER="${USER:-}"
INSTANCE_IP="${INSTANCE_IP:-}"

if [ -z "$PRIVATE_KEY_PATH" ] || [ -z "$USER" ] || [ -z "$INSTANCE_IP" ]; then
  echo "Error: Required environment variables not set (PRIVATE_KEY_PATH, USER, INSTANCE_IP)"
  exit 1
fi

if ! command -v ssh >/dev/null 2>&1 || ! command -v scp >/dev/null 2>&1; then
  echo "Error: ssh/scp not found"
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SSH_OPTS="-i $PRIVATE_KEY_PATH -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"
TARGET="$USER@$INSTANCE_IP"

scp $SSH_OPTS "$SCRIPT_DIR/startup.sh" "$TARGET:/tmp/startup.sh"

ssh $SSH_OPTS "$TARGET" "
if sudo docker --version >/dev/null 2>&1 && sudo systemctl is-active --quiet docker; then
  echo 'Docker already installed and running'
else
  chmod +x /tmp/startup.sh
  bash /tmp/startup.sh '$USER'
  if ! sudo docker --version >/dev/null 2>&1; then
    if [ ! -f /usr/bin/docker ]; then
      echo 'Error: Docker installation failed'
      exit 1
    fi
  fi
  echo 'Docker installed successfully'
fi
"
