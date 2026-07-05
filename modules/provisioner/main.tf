resource "null_resource" "install_docker" {
  triggers = {
    instance_ip = var.instance_ip
    user        = var.user
  }

  provisioner "local-exec" {
    command     = "${path.module}/deploy-install-docker.sh"
    interpreter = ["/bin/sh"]
    environment = {
      PRIVATE_KEY_PATH = var.privatekeypath
      USER             = var.user
      INSTANCE_IP      = var.instance_ip
    }
    on_failure = continue
  }

  provisioner "local-exec" {
    command     = "${path.module}/deploy-install-docker.ps1"
    interpreter = ["PowerShell", "-NoProfile", "-File"]
    environment = {
      PRIVATE_KEY_PATH = var.privatekeypath
      USER             = var.user
      INSTANCE_IP      = var.instance_ip
    }
  }
}

resource "null_resource" "restore_backup" {
  depends_on = [null_resource.install_docker]

  triggers = {
    instance_ip = var.instance_ip
    backup_path = var.backup_path
  }

  provisioner "local-exec" {
    command     = "${path.root}/modules/backup/restore.sh"
    interpreter = ["/bin/sh"]
    environment = {
      PRIVATE_KEY_PATH = var.privatekeypath
      USER             = var.user
      INSTANCE_IP      = var.instance_ip
      BACKUP_PATH      = var.backup_path
    }
    on_failure = continue
  }

  provisioner "local-exec" {
    command     = "${path.root}/modules/backup/restore.ps1"
    interpreter = ["PowerShell", "-NoProfile", "-File"]
    environment = {
      PRIVATE_KEY_PATH = var.privatekeypath
      USER             = var.user
      INSTANCE_IP      = var.instance_ip
      BACKUP_PATH      = var.backup_path
    }
  }
}

resource "null_resource" "run_3x_ui" {
  depends_on = [null_resource.install_docker, null_resource.restore_backup]

  triggers = {
    instance_ip     = var.instance_ip
    user            = var.user
    v2ray_host      = var.v2ray_host
    panel_port      = var.panel_port
    panel_base_path = var.panel_base_path
    xui_image       = var.xui_image
  }

  provisioner "local-exec" {
    command     = "${path.module}/deploy-run-3x-ui.sh"
    interpreter = ["/bin/sh"]
    environment = {
      PRIVATE_KEY_PATH = var.privatekeypath
      USER             = var.user
      INSTANCE_IP      = var.instance_ip
      V2RAY_HOST       = var.v2ray_host
      PANEL_PORT       = tostring(var.panel_port)
      PANEL_BASE_PATH  = var.panel_base_path
      XUI_IMAGE        = var.xui_image
    }
    on_failure = continue
  }

  provisioner "local-exec" {
    command     = "${path.module}/deploy-run-3x-ui.ps1"
    interpreter = ["PowerShell", "-NoProfile", "-File"]
    environment = {
      PRIVATE_KEY_PATH = var.privatekeypath
      USER             = var.user
      INSTANCE_IP      = var.instance_ip
      V2RAY_HOST       = var.v2ray_host
      PANEL_PORT       = tostring(var.panel_port)
      PANEL_BASE_PATH  = var.panel_base_path
      XUI_IMAGE        = var.xui_image
    }
  }
}

resource "null_resource" "install_caddy" {
  count      = var.enable_caddy_tls ? 1 : 0
  depends_on = [null_resource.run_3x_ui]

  triggers = {
    instance_ip = var.instance_ip
    v2ray_host  = var.v2ray_host
    panel_port  = var.panel_port
  }

  provisioner "local-exec" {
    command     = "${path.module}/deploy-install-caddy.sh"
    interpreter = ["/bin/sh"]
    environment = {
      PRIVATE_KEY_PATH = var.privatekeypath
      USER             = var.user
      INSTANCE_IP      = var.instance_ip
      V2RAY_HOST       = var.v2ray_host
      PANEL_PORT       = tostring(var.panel_port)
    }
    on_failure = continue
  }

  provisioner "local-exec" {
    command     = "${path.module}/deploy-install-caddy.ps1"
    interpreter = ["PowerShell", "-NoProfile", "-File"]
    environment = {
      PRIVATE_KEY_PATH = var.privatekeypath
      USER             = var.user
      INSTANCE_IP      = var.instance_ip
      V2RAY_HOST       = var.v2ray_host
      PANEL_PORT       = tostring(var.panel_port)
    }
  }
}

resource "null_resource" "setup_cron_restart" {
  depends_on = [null_resource.install_docker, null_resource.run_3x_ui]

  triggers = {
    instance_ip           = var.instance_ip
    cron_restart_schedule = var.cron_restart_schedule
  }

  provisioner "local-exec" {
    command     = "${path.module}/deploy-setup-cron.sh"
    interpreter = ["/bin/sh"]
    environment = {
      PRIVATE_KEY_PATH      = var.privatekeypath
      USER                  = var.user
      INSTANCE_IP           = var.instance_ip
      CRON_RESTART_SCHEDULE = var.cron_restart_schedule
    }
    on_failure = continue
  }

  provisioner "local-exec" {
    command     = "${path.module}/deploy-setup-cron.ps1"
    interpreter = ["PowerShell", "-NoProfile", "-File"]
    environment = {
      PRIVATE_KEY_PATH      = var.privatekeypath
      USER                  = var.user
      INSTANCE_IP           = var.instance_ip
      CRON_RESTART_SCHEDULE = var.cron_restart_schedule
    }
  }
}
