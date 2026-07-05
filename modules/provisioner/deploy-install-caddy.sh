#!/bin/sh
# Upload install-caddy.sh and configure Caddy (OpenSSH local-exec; Unix).

set -e

PRIVATE_KEY_PATH="${PRIVATE_KEY_PATH:-}"
USER="${USER:-}"
INSTANCE_IP="${INSTANCE_IP:-}"
V2RAY_HOST="${V2RAY_HOST:-}"
PANEL_PORT="${PANEL_PORT:-2053}"

if [ -z "$PRIVATE_KEY_PATH" ] || [ -z "$USER" ] || [ -z "$INSTANCE_IP" ] || [ -z "$V2RAY_HOST" ]; then
  echo "Error: Required environment variables not set"
  exit 1
fi

if ! command -v ssh >/dev/null 2>&1 || ! command -v scp >/dev/null 2>&1; then
  echo "Error: ssh/scp not found"
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SSH_OPTS="-i $PRIVATE_KEY_PATH -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"
TARGET="$USER@$INSTANCE_IP"

scp $SSH_OPTS "$SCRIPT_DIR/install-caddy.sh" "$TARGET:/tmp/install-caddy.sh"

ssh $SSH_OPTS "$TARGET" "
chmod +x /tmp/install-caddy.sh
bash /tmp/install-caddy.sh '$V2RAY_HOST' $PANEL_PORT 2>&1 | tee /tmp/caddy-install.log || { echo 'Caddy install failed' >&2; exit 1; }
"
