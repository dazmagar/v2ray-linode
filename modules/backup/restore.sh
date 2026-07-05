#!/bin/sh
# Restore 3x-ui backup from local backup_path/current to the instance.
# Run before run_3x_ui on a new/fresh instance so the panel starts with existing configs.

set -e

PRIVATE_KEY_PATH="${PRIVATE_KEY_PATH:-${TF_VAR_privatekeypath}}"
USER="${USER:-${TF_VAR_user}}"
INSTANCE_IP="${INSTANCE_IP:-${TF_VAR_instance_ip}}"
BACKUP_PATH="${BACKUP_PATH:-${TF_VAR_backup_path}}"

if [ -z "$PRIVATE_KEY_PATH" ] || [ -z "$USER" ] || [ -z "$INSTANCE_IP" ] || [ -z "$BACKUP_PATH" ]; then
  echo "Error: Required environment variables not set"
  exit 1
fi

CURRENT="$BACKUP_PATH/current"
if [ ! -d "$CURRENT" ] || [ -z "$(ls -A "$CURRENT" 2>/dev/null)" ]; then
  echo "No backup to restore (missing or empty $CURRENT); skipping restore"
  exit 0
fi

if ! command -v ssh >/dev/null 2>&1 || ! command -v scp >/dev/null 2>&1; then
  echo "Error: ssh/scp not found"
  exit 1
fi

REMOTE_XUI="/home/$USER/x-ui"
SSH_OPTS="-i $PRIVATE_KEY_PATH -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"

echo "Restoring 3x-ui backup from $CURRENT to $USER@$INSTANCE_IP:$REMOTE_XUI"
ssh $SSH_OPTS "$USER@$INSTANCE_IP" "mkdir -p $REMOTE_XUI && sudo chown -R $USER:$USER $REMOTE_XUI"
scp $SSH_OPTS -r "$CURRENT/"* "$USER@$INSTANCE_IP:$REMOTE_XUI/"
echo "Restore completed"
