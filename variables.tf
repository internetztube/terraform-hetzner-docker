variable "name" {
  description = "Prefix used for all created resources"
  type        = string
}

variable "server_type" {
  description = "Hetzner server type such as cx22"
  type        = string
}

variable "location" {
  description = "Hetzner data center location identifier"
  type        = string
}

variable "floating_ip" {
  description = "Optional floating IP configuration"
  type = object({
    id         = number
    ip_address = string
    type       = string
  })
  default = null
}

variable "volume" {
  description = "Optional volume to attach; only ext4 supported"
  type = object({
    id = number
  })
  default = null
}

variable "ssh_key_id" {
  description = "Identifier of the Hetzner SSH key to provision"
  type        = string
}

variable "ssh_private_key" {
  description = "Private key used for remote provisioning"
  type        = string
  sensitive   = true
}

variable "keep_disk" {
  description = "Keep existing disk when server image changes"
  type        = bool
  default     = true
}

variable "containers_folder" {
  description = "Path to Docker container build contexts"
  type        = string
}

variable "backups" {
  description = "Enable Hetzner automatic backups"
  type        = bool
  default     = true
}

variable "docker_compose_file_path" {
  description = "Path to docker-compose.yml that should be deployed"
  type        = string
}

variable "firewall_ids" {
  description = "Additional firewall IDs to attach to the server"
  type        = list(number)
  default     = []
}

variable "create_final_snapshot" {
  description = "Create final snapshot on destroy; requires hcloud token in env"
  type        = bool
  default     = true
}

variable "env_variables" {
  description = "Extra environment variables passed to docker-compose"
  type        = list(object({ name = string, value = string }))
  default     = []
}

locals {
  container_artifacts_folder_path = "${var.containers_folder}/../container-artifacts"
}
