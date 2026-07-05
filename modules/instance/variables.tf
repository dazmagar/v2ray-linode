variable "region" {
  type        = string
  description = "Linode region"
}

variable "user" {
  type        = string
  description = "SSH username (created via cloud-init)"
}

variable "publickeypath" {
  type        = string
  description = "Path to public SSH key file"
}

variable "instance_label" {
  type        = string
  description = "Linode instance label"
  default     = "v2ray-server"
}

variable "boot_image" {
  type        = string
  description = "Linode image slug"
  default     = "linode/ubuntu24.04"
}

variable "instance_type" {
  type        = string
  description = "Linode plan type"
  default     = "g6-nanode-1"
}

variable "panel_port" {
  type        = number
  description = "3x-ui panel port (excluded from firewall when enable_caddy_tls)"
  default     = 2053
}

variable "enable_caddy_tls" {
  type        = bool
  description = "When true, panel_port is not opened in Cloud Firewall (use Caddy on 443)"
  default     = true
}

variable "firewall_tcp_ports" {
  type        = list(string)
  description = "Allowed TCP ports (computed in root module)"
}

variable "firewall_udp_ports" {
  type        = list(string)
  description = "Allowed UDP ports (computed in root module)"
}
