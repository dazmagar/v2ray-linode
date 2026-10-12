# V2Ray 3x-ui - Terraform deployment for Linode (Akamai Cloud)

Terraform module for deploying a V2Ray/Xray VPN server with **3x-ui** web panel on [Linode](https://cloud.linode.com/linodes). Includes Docker-based 3x-ui, optional Caddy TLS, Cloud Firewall, and backup/restore of the panel database.  
Based on the official **3x-ui** project: https://github.com/MHSanaei/3x-ui

## Links

- **3x-ui**: https://github.com/MHSanaei/3x-ui
- **Xray-core**: https://github.com/XTLS/Xray-core
- **Linode Cloud Manager**: https://cloud.linode.com/linodes
- **Linode Terraform provider**: https://registry.terraform.io/providers/linode/linode/latest/docs
- **Region availability**: https://www.akamai.com/why-akamai/global-infrastructure/availability

## Features

- Automated deployment of Xray server with 3x-ui web panel (VMess, VLESS, Trojan, Shadowsocks)
- Docker-based 3x-ui (official image, **pinned tag** via `xui_image` in tfvars)
- Linode Cloud Firewall (inbound DROP by default, explicit allow rules)
- Cloud-init creates a dedicated SSH user (not root-only)
- Optional backup of 3x-ui panel database
- Optional cron for container restart

## Client applications

- **Android (NekoBox)**: https://github.com/MatsuriDayo/NekoBoxForAndroid/releases
- **Windows (v2rayN)**: https://github.com/2dust/v2rayN/releases
- **iOS (V2Box - V2ray Client)**: https://apps.apple.com/us/app/v2box-v2ray-client/id6446814690

## Prerequisites

- Terraform >= 1.0
- Linode account with billing enabled
- **Personal Access Token** (API v4) - see below
- SSH key pair for instance access
- OpenSSH client (`ssh`, `scp`) on the machine where you run `terraform apply`

---

## Linode API token

Linode does not use cloud service accounts. Terraform authenticates with a **Personal Access Token** (API v4) tied to your account.

### Create a token

1. Sign in to [Akamai Cloud Manager](https://cloud.linode.com/).
2. Open **API Tokens**: https://cloud.linode.com/profile/tokens
3. Click **Create A Personal Access Token**.
4. Set a **Label** (e.g. `terraform-v2ray`).
5. **Expiry**: choose a duration (or **Never** for dev; for production prefer a limited expiry and rotation).
6. **Scopes** - set access in the table (everything else stays **No Access**):

   | Scope | Access | Why |
   |-------|--------|-----|
   | **Linodes** | **Read/Write** | Create, update, and delete the VPN instance |
   | **Firewalls** | **Read/Write** | Create Cloud Firewall and attach it to the instance |
   | Account, Databases, Domains, Events, Images, IPs, Kubernetes, Longview, Monitor, NodeBalancers, Object Storage, StackScripts, Volumes, VPCs | **No Access** | Not used by this project |

   Do **not** use **Select All** - that grants full account access.

7. Click **Create Token** and **copy the token immediately** - it is shown only once.

### Provide the token to Terraform

**Option A - environment variable (recommended):**

```powershell
$env:LINODE_TOKEN = "your_token_here"
terraform apply
```

The `linode` provider reads `LINODE_TOKEN` when `linode_token` is not set in tfvars.

**Option B - tfvars file (do not commit):**

```hcl
linode_token = "your_token_here"
```

`terraform.tfvars` is listed in `.gitignore`.

**Option C - token file:**

```powershell
# keys/linode.token - single line, no quotes; keys/* is gitignored
$env:LINODE_TOKEN = Get-Content -Raw keys/linode.token
```

Never commit tokens to git. If a token is leaked, revoke it in Cloud Manager and create a new one.

---

## Quick start

1. Clone this repository and enter the project directory.

2. Generate an SSH key pair (if you do not have one yet):

   ```powershell
   ssh-keygen -t ed25519 -f $env:USERPROFILE\.ssh\id_ed25519 -N '""'
   ```

3. Copy the example configuration:

   ```powershell
   Copy-Item terraform.tfvars.example terraform.tfvars
   ```

   ```bash
   cp terraform.tfvars.example terraform.tfvars
   ```

4. Edit `terraform.tfvars`:
   - `region` - nearest region ([list](https://www.linode.com/docs/products/compute/compute-instances/availability/)), e.g. `us-east`, `us-iad`, `eu-central`
   - SSH key paths (`publickeypath`, `privatekeypath`)
   - `v2ray_host` - domain or IP (after apply, point a DNS A record to `terraform output instance_ip`)
   - `instance_type` - default `g6-nanode-1` (~$5/mo, 1 GB RAM)

5. Set the token and apply:

   ```powershell
   $env:LINODE_TOKEN = "your_token_here"
   terraform init
   terraform apply
   ```

6. Open the panel:

   ```powershell
   terraform output panel_url
   ```

   Default login: `admin` / `admin` - change immediately in Panel Settings.

7. DNS (if using a domain and Caddy TLS):

   - A record: `v2ray_host` → `instance_ip`
   - Wait for propagation, then open `panel_url` (HTTPS via Caddy on port 443)

---

## Configuration

- **v2ray_host** - Server IP or FQDN (used in client connection links). With Caddy TLS, Caddy serves this hostname only - access via IP in the browser will not work.
- **panel_base_path** - Custom URL prefix for the 3x-ui panel (e.g. `xyz-a1b2c3d4/`). When set, use `terraform output panel_url` as-is; do **not** append `/panel` (that suffix replaces the default `/panel/` path).
- **xui_image** - Pinned 3x-ui Docker image tag. Example: `ghcr.io/mhsanaei/3x-ui:v3.10.0`. Do not use `:latest`.
- **Firewall:** `firewall_tcp_ports` / `firewall_udp_ports` in tfvars; **`proxy_port` is always merged into TCP**, **`panel_port` is merged only when `enable_caddy_tls = false`**.

### US East regions (North America)

| `region` slug  | Location       |
|----------------|----------------|
| `us-east`      | Newark, NJ     |
| `us-iad`       | Washington, DC |
| `us-southeast` | Atlanta, GA    |
| `us-mia`       | Miami, FL      |

For US East Coast workloads, `us-east` (Newark) is the most common choice.

## Provisioning (SSH)

Provisioner steps use **local-exec** with `deploy-*.ps1` (Windows) and `deploy-*.sh` (Unix), calling **OpenSSH** (`ssh`/`scp`). This avoids Terraform’s built-in SSH provisioner issues with **ed25519** keys on Windows.

On Windows, PowerShell scripts use `modules/openssh-helper.ps1` to resolve `ssh`/`scp` paths reliably, wait for SSH after instance creation, and retry on transient `Connection reset` errors.

If a PowerShell provisioner step fails, `terraform apply` stops with an error.

## Backup and restore

- A normal **`terraform apply`** (without recreating the instance) does **not** wipe panel configs: data lives on the VM disk in `/home/<user>/x-ui/`.
- **Manual backup:**
  ```powershell
  terraform apply -replace="module.backup.null_resource.backup_xui"
  ```
- **Restore:** if `backup_path/current/` exists and is not empty when you run `terraform apply` (e.g. after redeploy), the provisioner restores it before starting 3x-ui.

## Troubleshooting

- Panel URL: `terraform output panel_url`
- SSH: `ssh -i <private_key> <user>@<instance_ip>`
- Container: `sudo docker ps -a --filter "name=3x-ui"`
- Logs: `sudo docker logs 3x-ui`
- Firewall in UI: https://cloud.linode.com/firewalls

## Destroy

```powershell
terraform destroy
```

Removes the Linode, Cloud Firewall, and related resources in your account.
