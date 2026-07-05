#!/bin/sh
# Upload setup-cron-restart.sh and install cron job (OpenSSH local-exec; Unix).

set -e

PRIVATE_KEY_PATH="${PRIVATE_KEY_PATH:-}"
USER="${USER:-}"
INSTANCE_IP="${INSTANCE_IP:-}"
CRON_RESTART_SCHEDULE="${CRON_RESTART_SCHEDULE:-}"

if [ -z "$PRIVATE_KEY_PATH" ] || [ -z "$USER" ] || [ -z "$INSTANCE_IP" ] || [ -z "$CRON_RESTART_SCHEDULE" ]; then
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
REMOTE_SCRIPT="/home/$USER/setup-cron-restart.sh"

scp $SSH_OPTS "$SCRIPT_DIR/setup-cron-restart.sh" "$TARGET:$REMOTE_SCRIPT"

ssh $SSH_OPTS "$TARGET" "
chmod +x $REMOTE_SCRIPT
bash $REMOTE_SCRIPT '$CRON_RESTART_SCHEDULE' || { echo 'ERROR: Failed to setup cron job' >&2; exit 1; }
crontab -l | grep -q '3x-ui' && echo 'Cron job verified' || echo 'WARNING: Cron job not found'
"
