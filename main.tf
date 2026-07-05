provider "linode" {
  token = var.linode_token
}

locals {
  firewall_tcp_ports = distinct(concat(
    [for p in var.firewall_tcp_ports : tostring(p)],
    [tostring(var.proxy_port)],
    var.enable_caddy_tls ? [] : [tostring(var.panel_port)],
  ))
  firewall_udp_ports = distinct([for p in var.firewall_udp_ports : tostring(p)])
}

module "instance" {
  source             = "./modules/instance"
  region             = var.region
  user               = var.user
  publickeypath      = var.publickeypath
  instance_label     = var.instance_label
  boot_image         = var.boot_image
  instance_type      = var.instance_type
  panel_port         = var.panel_port
  enable_caddy_tls   = var.enable_caddy_tls
  firewall_tcp_ports = local.firewall_tcp_ports
  firewall_udp_ports = local.firewall_udp_ports
}

# Backup runs when instance id/ip changes; on-demand: terraform apply -replace="module.backup.null_resource.backup_xui"
module "backup" {
  source         = "./modules/backup"
  instance_id    = module.instance.instance_id
  instance_ip    = module.instance.instance_ip
  user           = var.user
  privatekeypath = var.privatekeypath
  backup_path    = var.backup_path
}

module "provisioner" {
  depends_on            = [module.instance.vpn_instance, module.backup]
  source                = "./modules/provisioner"
  instance_ip           = module.instance.instance_ip
  user                  = var.user
  privatekeypath        = var.privatekeypath
  backup_path           = var.backup_path
  v2ray_host            = var.v2ray_host
  panel_port            = var.panel_port
  panel_base_path       = var.panel_base_path
  enable_caddy_tls      = var.enable_caddy_tls
  panel_host            = var.panel_host
  cron_restart_schedule = var.cron_restart_schedule
  xui_image             = var.xui_image
}
