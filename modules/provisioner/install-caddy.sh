#!/bin/bash
set -e

# Args: SITE_HOST (FQDN), PANEL_PORT (3x-ui backend). Caddy listens on 443; proxy (Xray) uses another port.
SITE_HOST="${1:?Missing SITE_HOST}"
PANEL_PORT="${2:-2053}"

LOG_FILE="/tmp/caddy-install.log"
echo "Installing Caddy: ${SITE_HOST}:443 -> localhost:${PANEL_PORT}" | tee "${LOG_FILE}"

if command -v caddy &>/dev/null; then
  echo "Caddy already installed" | tee -a "${LOG_FILE}"
else
  echo "Adding Caddy repository and installing..." | tee -a "${LOG_FILE}"
  sudo apt-get update -qq
  sudo apt-get install -y debian-keyring debian-archive-keyring apt-transport-https curl
  curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/gpg.key' | sudo gpg --dearmor -o /usr/share/keyrings/caddy-stable-archive-keyring.gpg
  curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/debian.deb.txt' | sudo tee /etc/apt/sources.list.d/caddy-stable.list
  sudo apt-get update -qq
  sudo apt-get install -y caddy
fi

CADDYFILE="/etc/caddy/Caddyfile"
sudo tee "${CADDYFILE}" >/dev/null <<EOF
# 3x-ui panel on 443; set VLESS/Reality inbound port in panel to proxy_port (e.g. 8443)
${SITE_HOST} {
	reverse_proxy 127.0.0.1:${PANEL_PORT}
}
EOF

echo "Caddyfile written. Restarting Caddy..." | tee -a "${LOG_FILE}"
sudo systemctl enable caddy
sudo systemctl restart caddy

if sudo systemctl is-active --quiet caddy; then
  echo "Caddy is running. Panel: https://${SITE_HOST}" | tee -a "${LOG_FILE}"
else
  echo "WARNING: Caddy may have failed. Check: sudo journalctl -u caddy -n 50" | tee -a "${LOG_FILE}"
  exit 1
fi
