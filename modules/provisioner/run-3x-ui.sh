#!/bin/bash
set -e

# Args: V2RAY_HOST (FQDN), PANEL_PORT, PANEL_BASE_PATH, XUI_IMAGE
V2RAY_HOST="${1:-}"
PANEL_PORT="${2:-2053}"
PANEL_BASE_PATH="${3:-}"
XUI_IMAGE="${4:-}"

container_name="3x-ui"
image="${XUI_IMAGE:?XUI_IMAGE (4th arg) is required}"
LOG_FILE="/tmp/3x-ui-container-deploy.log"

echo "Starting 3x-ui container deployment..." | tee "${LOG_FILE}"

if ! sudo docker images -q "${image}" | grep -q .; then
  echo "Pulling Docker image ${image}..." | tee -a "${LOG_FILE}"
  sudo docker pull "${image}" 2>&1 | tee -a "${LOG_FILE}"
fi

CURRENT_USER=$(whoami)
XUI_BASE="/home/${CURRENT_USER}/x-ui"
XUI_DB="${XUI_BASE}/db"
XUI_CERT="${XUI_BASE}/cert"

sudo mkdir -p "${XUI_DB}" "${XUI_CERT}"
sudo chown -R "${CURRENT_USER}:${CURRENT_USER}" "${XUI_BASE}"

container_id=$(sudo docker ps -a -q --filter "name=${container_name}")
if [ -n "$container_id" ]; then
  echo "Stopping and removing existing container: ${container_name}" | tee -a "${LOG_FILE}"
  sudo docker stop ${container_name} || true
  sudo docker rm ${container_name} || true
fi

echo "Starting 3x-ui container (panel port ${PANEL_PORT})..." | tee -a "${LOG_FILE}"
if ! sudo docker run -d \
  --name="${container_name}" \
  -e XRAY_VMESS_AEAD_FORCED=false \
  -e XUI_ENABLE_FAIL2BAN=true \
  -v "${XUI_DB}:/etc/x-ui/" \
  -v "${XUI_CERT}:/root/cert/" \
  --network=host \
  --restart=unless-stopped \
  "${image}"; then
  echo "ERROR: Failed to start container" | tee -a "${LOG_FILE}"
  sudo docker logs ${container_name} 2>&1 | tee -a "${LOG_FILE}" || true
  exit 1
fi

echo "Waiting for panel to init DB..." | tee -a "${LOG_FILE}"
sleep 8

echo "Applying panel port ${PANEL_PORT}..." | tee -a "${LOG_FILE}"
sudo docker exec ${container_name} /app/x-ui setting -port "${PANEL_PORT}" 2>&1 | tee -a "${LOG_FILE}" || true
if [ -n "${PANEL_BASE_PATH}" ]; then
  path="${PANEL_BASE_PATH}"
  [ "${path:0:1}" != "/" ] && path="/${path}"
  [ "${path: -1}" != "/" ] && path="${path}/"
  echo "Applying panel base path ${path}..." | tee -a "${LOG_FILE}"
  sudo docker exec ${container_name} /app/x-ui setting -webBasePath "${path}" 2>&1 | tee -a "${LOG_FILE}" || true
fi

echo "Restarting container to apply settings..." | tee -a "${LOG_FILE}"
sudo docker restart ${container_name}
sleep 5

BASE_PATH="${PANEL_BASE_PATH}"
[ -n "${BASE_PATH}" ] && [ "${BASE_PATH:0:1}" != "/" ] && BASE_PATH="/${BASE_PATH}"
[ -n "${BASE_PATH}" ] && [ "${BASE_PATH: -1}" != "/" ] && BASE_PATH="${BASE_PATH}/"
[ -z "${BASE_PATH}" ] && BASE_PATH="/panel/"

echo "Container started. Panel: http://<this_host>:${PANEL_PORT}${BASE_PATH} (default admin/admin)" | tee -a "${LOG_FILE}"
if [ -n "${V2RAY_HOST}" ]; then
  echo "Use this URL so client links show FQDN: http://${V2RAY_HOST}:${PANEL_PORT}${BASE_PATH}" | tee -a "${LOG_FILE}"
fi
sudo docker ps --filter "name=${container_name}" | tee -a "${LOG_FILE}"
