# Hetzner Terraform Docker

Terraform module that provisions a Hetzner Cloud server and deploys
containers via Docker Compose. The module handles server creation,
optional volume and floating IP attachment and uploads container images
to the host.

## Features
- Volume attachment
- Server final snapshot
- Floating IP support
- Environment variables for Docker Compose
- Custom `docker build` commands
- Local Docker registry via `docker save` and `docker load`

## Usage

```terraform
module "main" {
  source                   = "github.com/internetztube/hetzner-terraform-docker/modules/default"
  name                     = "main"
  server_type              = "cx22"
  location                 = "nbg1"
  floating_ip              = hcloud_floating_ip.main
  volume                   = hcloud_volume.main
  firewall_ids             = [hcloud_firewall.http.id]
  backups                  = true
  create_final_snapshot    = true
  containers_folder        = abspath("./containers")
  docker_compose_file_path = abspath("./docker-compose.yml")
  ssh_key_id               = hcloud_ssh_key.default.id
  ssh_private_key          = var.ssh_private_key
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| name | Prefix used for all created resources | string | n/a | yes |
| server_type | Hetzner server type such as cx22 | string | n/a | yes |
| location | Hetzner data center location identifier | string | n/a | yes |
| floating_ip | Optional floating IP configuration | object({id number, ip_address string, type string}) | null | no |
| volume | Optional volume to attach; only ext4 supported | object({id number}) | null | no |
| ssh_key_id | Identifier of the Hetzner SSH key to provision | string | n/a | yes |
| ssh_private_key | Private key used for remote provisioning | string | n/a | yes |
| keep_disk | Keep existing disk when server image changes | bool | true | no |
| containers_folder | Path to Docker container build contexts | string | n/a | yes |
| backups | Enable Hetzner automatic backups | bool | true | no |
| docker_compose_file_path | Path to docker-compose.yml that should be deployed | string | n/a | yes |
| firewall_ids | Additional firewall IDs to attach to the server | list(number) | [] | no |
| create_final_snapshot | Create final snapshot on destroy; requires hcloud token in env | bool | true | no |
| env_variables | Extra environment variables passed to docker-compose | list(object({name string, value string})) | [] | no |

## Outputs

| Name | Description |
|------|-------------|
| server_id | ID of the created server |
| server_ipv4 | Public IPv4 address of the server |
| server_ipv6 | Public IPv6 address of the server |
| firewall_id_ssh | ID of the default SSH firewall |

## Not included
- Support for SSL/TLS
- traefik
- Volume backups

