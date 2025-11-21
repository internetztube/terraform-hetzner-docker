variable "name" {
  type = string
}

variable "server_type" {
  type = string
}

variable "location" {
  type = string
}

variable "floating_ip" {
  type = object({
    id         = number
    ip_address = string
    type       = string
  })
  default = null
}

variable "volume" {
  type = object({
    id = number
  })
  default     = null
  description = "Only ext4 is supported!"
}

variable "ssh_key_id" {
  type = string
}

variable "ssh_private_key" {
  type = string
}

variable "keep_disk" {
  type    = bool
  default = true
}

variable "containers_folder" {
  type = string
}

variable "backups" {
  type    = bool
  default = true
}

variable "docker_compose_file_path" {
  type = string
}

variable "firewall_ids" {
  type    = list(number)
  default = []
}

variable "create_final_snapshot" {
  type        = bool
  default     = true
  description = "Requires \"HCLOUD_TOKEN\" or \"TF_VAR_hcloud_token\" environment variable in pipeline."
}

variable "env_variables" {
  type    = list(object({ name = string, value = string }))
  default = []
}

locals {
  container_artifacts_folder_path = "${var.containers_folder}/../container-artifacts"
}
