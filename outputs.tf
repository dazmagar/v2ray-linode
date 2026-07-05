output "instance_ip" {
  value       = module.instance.instance_ip
  description = "Linode public IPv4"
}

locals {
  panel_path       = var.panel_base_path != "" ? (substr(var.panel_base_path, 0, 1) == "/" ? var.panel_base_path : "/${var.panel_base_path}") : "/panel/"
  panel_path_slash = substr(local.panel_path, length(local.panel_path) - 1, 1) == "/" ? local.panel_path : "${local.panel_path}/"
}

output "panel_url" {
  value       = var.enable_caddy_tls ? "https://${var.v2ray_host}${local.panel_path_slash}" : "http://${var.v2ray_host}:${var.panel_port}${local.panel_path_slash}"
  description = "Panel URL. With Caddy: HTTPS on 443 (no port in URL)."
}

output "proxy_port" {
  value       = var.proxy_port
  description = "Use this port for VLESS/Reality inbound in 3x-ui (panel is on 443)."
}
