terraform {
  required_providers {
    linode = {
      source  = "linode/linode"
      version = "~> 3.0"
    }
  }
}

locals {
  ssh_public_key = trimspace(file(var.publickeypath))
  tcp_ports      = join(",", var.firewall_tcp_ports)
  udp_ports      = join(",", var.firewall_udp_ports)
}

resource "linode_instance" "vpn_instance" {
  label  = var.instance_label
  region = var.region
  type   = var.instance_type
  image  = var.boot_image

  # Required when deploying from image; cloud-init also provisions the app user below.
  authorized_keys = [local.ssh_public_key]

  metadata {
    user_data = base64encode(templatefile("${path.module}/cloud-init.yml.tpl", {
      username   = var.user
      public_key = local.ssh_public_key
    }))
  }

  tags = ["v2ray-server"]

  lifecycle {
    ignore_changes = [image]
  }
}

resource "linode_firewall" "default" {
  label = "${var.instance_label}-firewall"

  inbound_policy  = "DROP"
  outbound_policy = "ACCEPT"

  dynamic "inbound" {
    for_each = length(var.firewall_tcp_ports) > 0 ? [1] : []
    content {
      label    = "allow-tcp"
      action   = "ACCEPT"
      protocol = "TCP"
      ports    = local.tcp_ports
      ipv4     = ["0.0.0.0/0"]
      ipv6     = ["::/0"]
    }
  }

  dynamic "inbound" {
    for_each = length(var.firewall_udp_ports) > 0 ? [1] : []
    content {
      label    = "allow-udp"
      action   = "ACCEPT"
      protocol = "UDP"
      ports    = local.udp_ports
      ipv4     = ["0.0.0.0/0"]
      ipv6     = ["::/0"]
    }
  }

  linodes = [linode_instance.vpn_instance.id]
}
