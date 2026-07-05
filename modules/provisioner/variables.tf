variable "user" {
  type        = string
  description = "SSH username for VM instance access"
}

variable "privatekeypath" {
  type        = string
  description = "Path to private SSH key file (id_rsa)"
}

variable "instance_ip" {
  type        = string
  description = "Public IP address of the compute instance"
}

variable "backup_path" {
  type        = string
  description = "Local path for 3x-ui backup (used for restore when backup_path/current exists)"
  default     = ""
}

variable "v2ray_host" {
  type        = string
  description = "V2Ray/Xray panel host IP or FQDN (for client links)"
}

variable "panel_port" {
  type        = number
  description = "3x-ui panel listen port"
  default     = 2053
}

variable "panel_base_path" {
  type        = string
  description = "3x-ui panel base path (e.g. /xui-xxx/). Empty = default /panel/"
  default     = ""
}

variable "enable_caddy_tls" {
  type        = bool
  description = "Install Caddy as reverse proxy with Let's Encrypt for panel HTTPS"
  default     = true
}


variable "panel_host" {
  type        = string
  description = "Panel host: subdomain prefix (e.g. 'ui') or full FQDN. Empty = panel.<v2ray_host>"
  default     = ""
}

variable "cron_restart_schedule" {
  type        = string
  description = "Cron schedule for 3x-ui container restart"
  default     = "0 3 * * *"
}

variable "xui_image" {
  type        = string
  description = "Pinned 3x-ui Docker image (tag, not latest)"
}
