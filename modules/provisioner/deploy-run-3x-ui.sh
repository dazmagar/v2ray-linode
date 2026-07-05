#!/bin/sh
# Upload run-3x-ui.sh and start 3x-ui container (OpenSSH local-exec; Unix).

set -e

PRIVATE_KEY_PATH="${PRIVATE_KEY_PATH:-}"
USER="${USER:-}"
INSTANCE_IP="${INSTANCE_IP:-}"
V2RAY_HOST="${V2RAY_HOST:-}"
PANEL_PORT="${PANEL_PORT:-2053}"
PANEL_BASE_PATH="${PANEL_BASE_PATH:-}"
XUI_IMAGE="${XUI_IMAGE:-}"

if [ -z "$PRIVATE_KEY_PATH" ] || [ -z "$USER" ] || [ -z "$INSTANCE_IP" ] || [ -z "$XUI_IMAGE" ]; then
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
REMOTE_SCRIPT="/home/$USER/run-3x-ui.sh"

scp $SSH_OPTS "$SCRIPT_DIR/run-3x-ui.sh" "$TARGET:$REMOTE_SCRIPT"

ssh $SSH_OPTS "$TARGET" "
chmod +x $REMOTE_SCRIPT
bash $REMOTE_SCRIPT '$V2RAY_HOST' $PANEL_PORT '$PANEL_BASE_PATH' '$XUI_IMAGE' 2>&1 | tee /tmp/3x-ui-startup.log || {
  RC=\$?
  echo '=== Container startup failed (exit code: '\$RC') ===' >&2
  cat /tmp/3x-ui-container-deploy.log >&2 2>/dev/null || true
  sudo docker logs 3x-ui >&2 2>&1 || true
  exit \$RC
}
"
