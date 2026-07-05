variable "linode_token" {
  type        = string
  description = "Linode Personal Access Token (API v4). Leave null and set env LINODE_TOKEN instead."
  sensitive   = true
  default     = null
}

variable "region" {
  type        = string
  description = "Linode region (e.g. eu-central, us-east, ap-south)"
}

variable "user" {
  type        = string
  description = "SSH user on the Linode (created via cloud-init)"
}

variable "publickeypath" {
  type        = string
  description = "Path to SSH public key"
}

variable "privatekeypath" {
  type        = string
  description = "Path to SSH private key"
}

variable "v2ray_host" {
  type        = string
  description = "Server IP or hostname for client configs"
}

variable "panel_port" {
  type        = number
  description = "3x-ui panel listen port"
}

variable "panel_base_path" {
  type        = string
  description = "Panel base path segment; empty = default path"
}

variable "enable_caddy_tls" {
  type        = bool
  description = "Expose panel via Caddy with HTTPS"
}

variable "proxy_port" {
  type        = number
  description = "Xray proxy inbound port"
}

variable "firewall_tcp_ports" {
  type        = list(number)
  description = "Linode Cloud Firewall: allowed TCP ports (proxy_port always added; panel_port added when enable_caddy_tls is false)"
}

variable "firewall_udp_ports" {
  type        = list(number)
  description = "Linode Cloud Firewall: allowed UDP ports"
}

variable "panel_host" {
  type        = string
  description = "Caddy: subdomain or FQDN; empty uses default host"
}

variable "instance_label" {
  type        = string
  description = "Linode instance label (display name)"
}

variable "boot_image" {
  type        = string
  description = "Linode image slug (e.g. linode/ubuntu24.04)"
}

variable "instance_type" {
  type        = string
  description = "Linode plan type (e.g. g6-nanode-1)"
}

variable "cron_restart_schedule" {
  type        = string
  description = "Cron line for 3x-ui container restart"
}

variable "xui_image" {
  type        = string
  description = "Pinned 3x-ui Docker image (tag, not latest)"
}

variable "backup_path" {
  type        = string
  description = "Local directory for panel backups"
}
