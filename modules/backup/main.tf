# Runs provisioners when instance_id or instance_ip changes (e.g. VM recreated).
# On-demand backup while VM unchanged: terraform apply -replace="module.backup.null_resource.backup_xui"
resource "null_resource" "backup_xui" {
  triggers = {
    instance_id = var.instance_id
    instance_ip = var.instance_ip
  }

  provisioner "local-exec" {
    command     = "${path.module}/backup.sh"
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
    command     = "${path.module}/backup.ps1"
    interpreter = ["PowerShell", "-NoProfile", "-File"]
    environment = {
      PRIVATE_KEY_PATH = var.privatekeypath
      USER             = var.user
      INSTANCE_IP      = var.instance_ip
      BACKUP_PATH      = var.backup_path
    }
  }
}
