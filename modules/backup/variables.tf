variable "instance_id" {
  type        = string
  description = "ID of the compute instance"
}

variable "instance_ip" {
  type        = string
  description = "Public IP address of the compute instance"
}

variable "user" {
  type        = string
  description = "SSH username for VM instance access"
}

variable "privatekeypath" {
  type        = string
  description = "Path to private SSH key file (id_rsa)"
}

variable "backup_path" {
  type        = string
  description = "Local path for 3x-ui backup directory"
  default     = "./modules/backup/xui_backup"
}
