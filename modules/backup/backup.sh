#!/bin/sh
set -e

PRIVATE_KEY_PATH="${PRIVATE_KEY_PATH:-${TF_VAR_privatekeypath}}"
USER="${USER:-${TF_VAR_user}}"
INSTANCE_IP="${INSTANCE_IP:-${TF_VAR_instance_ip}}"
BACKUP_PATH="${BACKUP_PATH:-${TF_VAR_backup_path}}"

if [ -z "$PRIVATE_KEY_PATH" ] || [ -z "$USER" ] || [ -z "$INSTANCE_IP" ] || [ -z "$BACKUP_PATH" ]; then
  echo "Error: Required environment variables not set"
  exit 1
fi

if ! command -v ssh >/dev/null 2>&1; then
  echo "Error: ssh command not found"
  exit 1
fi

if ! command -v scp >/dev/null 2>&1; then
  echo "Error: scp command not found"
  exit 1
fi

if [ ! -d "$BACKUP_PATH" ]; then
  mkdir -p "$BACKUP_PATH"
fi

TIMESTAMP=$(date +%Y%m%d_%H%M%S)
YEAR=$(date +%Y)
YEAR_DIR="$BACKUP_PATH/$YEAR"
REMOTE_XUI="/home/$USER/x-ui"

echo "Backup directory: $BACKUP_PATH"
echo "Starting 3x-ui backup at $TIMESTAMP"

mkdir -p "$YEAR_DIR" "$BACKUP_PATH/current"

if ssh -i "$PRIVATE_KEY_PATH" -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null "$USER@$INSTANCE_IP" "test -d $REMOTE_XUI" 2>/dev/null; then
  scp -i "$PRIVATE_KEY_PATH" -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -r "$USER@$INSTANCE_IP:$REMOTE_XUI/" "$BACKUP_PATH/current/" 2>/dev/null || true
  if [ -d "$BACKUP_PATH/current" ]; then
    cp -r "$BACKUP_PATH/current" "$YEAR_DIR/xui.backup.$TIMESTAMP"
    echo "3x-ui backup saved to $YEAR_DIR/xui.backup.$TIMESTAMP"
  fi
else
  echo "Warning: Remote path $REMOTE_XUI not found or not accessible"
fi

echo "Backup completed"
