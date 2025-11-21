# Hetzner Terraform Docker

Terraform module that provisions a Hetzner Cloud server and deploys containers via Docker Compose. The module handles
server creation, optional volume and floating IP attachment, and uploads container images to the host.

## Features

- Volume attachment with automatic mounting
- Server final snapshot on destroy
- Floating IP support
- Environment variables for Docker Compose
- Custom `docker build` commands via `docker-build.sh` scripts
- Local Docker registry via `docker save` and `docker load`
- Automatic SSH firewall configuration
- Automatic directory creation for volumes

## Requirements

- Terraform >= 1.0
- Hetzner Cloud provider
- Docker installed locally (for building images)
- `docker` and `docker-compose` commands available in your PATH
- SSH key pair for server provisioning and deployment

## Usage

### Basic Example

```terraform
module "main" {
  source                   = "internetztube/docker/hetzner"
  name                     = "main"
  server_type              = "cx22"
  location                 = "nbg1"
  ssh_key_id               = hcloud_ssh_key.default.id
  ssh_private_key          = var.ssh_private_key
  containers_folder        = abspath("./containers")
  docker_compose_file_path = abspath("./containers/docker-compose.yml")
}
```

<details>
<summary><b>Complete Example with Optional Features</b></summary>

```terraform
resource "hcloud_ssh_key" "default" {
  name       = "main"
  public_key = var.ssh_public_key
}

resource "hcloud_floating_ip" "main" {
  type     = "ipv4"
  location = "nbg1"
}

resource "hcloud_volume" "main" {
  name     = "main"
  size     = 10
  location = "nbg1"
  format   = "ext4"
}

resource "hcloud_firewall" "http" {
  name = "http"
  rule {
    direction  = "in"
    protocol   = "tcp"
    port       = "80"
    source_ips = ["0.0.0.0/0", "::/0"]
  }
  rule {
    direction  = "in"
    protocol   = "tcp"
    port       = "443"
    source_ips = ["0.0.0.0/0", "::/0"]
  }
}

module "main" {
  source                   = "internetztube/docker/hetzner"
  name                     = "main"
  server_type              = "cx22"
  location                 = "nbg1"
  floating_ip              = hcloud_floating_ip.main
  volume                   = hcloud_volume.main
  firewall_ids             = [hcloud_firewall.http.id]
  backups                  = true
  create_final_snapshot    = true
  containers_folder        = abspath("./containers")
  docker_compose_file_path = abspath("./containers/docker-compose.yml")
  ssh_key_id               = hcloud_ssh_key.default.id
  ssh_private_key          = var.ssh_private_key
  env_variables            = [
    { name = "APP_ENV", value = "production" },
    { name = "APP_DEBUG", value = "false" },
    { name = "DATABASE_URL", value = var.database_url }
  ]
}
```

</details>

## How It Works

The module follows a three-phase deployment process:

1. **Build Phase**: Docker images are built locally from your `containers_folder`
2. **Transfer Phase**: Images are saved using `docker save` and transferred to the server via SSH
3. **Deploy Phase**: Images are loaded with `docker load` and Docker Compose starts the services

A default SSH firewall is automatically created and attached to the server.

When you run `terraform apply` again, the module rebuilds changed images and redeploys the containers.

## Configuration

### Project Structure

The `containers_folder` should contain your Docker Compose file and service build contexts:

```
./containers/
├── docker-compose.yml
├── web/
│   ├── Dockerfile
│   ├── docker-build.sh
│   └── ...
└── queue/
    ├── Dockerfile
    ├── docker-build.sh
    └── ...
```

**Docker Image Tagging**: Images are tagged based on the folder name. In the example above, the module
creates `web:latest` and `queue:latest` images.

**Custom Build Commands**: Each service folder can include a `docker-build.sh` script for custom build steps executed
before `docker build`.

```shell
#!/bin/bash
# Example docker-build.sh
echo $CONTAINER_TAG
docker build --build-arg nvmrc="$(cat src/.nvmrc)" -t "${CONTAINER_TAG}" -f Dockerfile .
```

**Environment Variables**: Variables from `env_variables` are written to `./.env` on the server and are available
within `docker-compose.yml` using `${VARIABLE_NAME}` syntax.

**Example docker-compose.yml**:

```yaml
services:
  web:
    image: web:latest
    restart: always
    user: "3000:3000"
    volumes:
      - ./storage/web/storage:/app/storage
    env_file:
      - ./.env
    ports:
      - "80:8080"
  queue:
    image: queue:latest
    restart: always
    cpus: 0.5
    user: "3000:3000"
    volumes:
      - ./storage/web/storage:/app/storage
    env_file:
      - ./.env
  mysql:
    image: mysql:9
    ports:
      - 3306:3306
    volumes:
      - ./storage/mysql:/var/lib/mysql
    environment:
      MYSQL_DATABASE: ${CRAFT_DB_DATABASE}
      MYSQL_USER: ${CRAFT_DB_USER}
      MYSQL_PASSWORD: ${CRAFT_DB_PASSWORD}
      MYSQL_ROOT_PASSWORD: ${CRAFT_DB_PASSWORD}
```

### Persistent Storage

When using volumes, ensure your `docker-compose.yml` maps them to paths that persist across container restarts:

```yaml
volumes:
  - ./storage/web/storage:/app/storage  # Mounted on host
  - ./storage/mysql:/var/lib/mysql      # Database persists here
```

The module automatically creates any folders referenced in `docker-compose.yml` that don't already exist on the host.

If you attach a Hetzner volume, it will be mounted at `/root/volume` on the server. You can reference this path in
your `docker-compose.yml` volume mappings.

### SSH Key Requirements

The module requires both a public and private SSH key:

- **Public Key**: Added to Hetzner Cloud via `hcloud_ssh_key` resource and used for server provisioning
- **Private Key**: Passed to the module via `ssh_private_key` parameter for SSH connections during deployment

The private key is used to transfer Docker images and execute deployment commands on the server.

### Final Snapshot on Destroy

If `create_final_snapshot` is enabled (default: `true`), the module creates a snapshot when destroying the server. This
requires the `HCLOUD_TOKEN` environment variable to be set in your CI/CD pipeline or local environment:

```bash
export HCLOUD_TOKEN=your_hetzner_api_token
terraform destroy
```

## Inputs

| Name                     | Description                                                    | Type                                                | Default | Required |
|--------------------------|----------------------------------------------------------------|-----------------------------------------------------|---------|:--------:|
| name                     | Prefix used for all created resources                          | string                                              | n/a     |   yes    |
| server_type              | Hetzner server type such as cx22                               | string                                              | n/a     |   yes    |
| location                 | Hetzner data center location identifier                        | string                                              | n/a     |   yes    |
| floating_ip              | Optional floating IP configuration                             | object({id number, ip_address string, type string}) | null    |    no    |
| volume                   | Optional volume to attach; only ext4 supported                 | object({id number})                                 | null    |    no    |
| ssh_key_id               | Identifier of the Hetzner SSH key to provision                 | string                                              | n/a     |   yes    |
| ssh_private_key          | Private key used for remote provisioning                       | string                                              | n/a     |   yes    |
| keep_disk                | Keep existing disk when server image changes                   | bool                                                | true    |    no    |
| containers_folder        | Path to Docker container build contexts                        | string                                              | n/a     |   yes    |
| backups                  | Enable Hetzner automatic backups                               | bool                                                | true    |    no    |
| docker_compose_file_path | Path to docker-compose.yml that should be deployed             | string                                              | n/a     |   yes    |
| firewall_ids             | Additional firewall IDs to attach to the server                | list(number)                                        | []      |    no    |
| create_final_snapshot    | Create final snapshot on destroy; requires HCLOUD_TOKEN in env | bool                                                | true    |    no    |
| env_variables            | Extra environment variables passed to docker-compose           | list(object({name string, value string}))           | []      |    no    |

## Outputs

| Name            | Description                       |
|-----------------|-----------------------------------|
| server_id       | ID of the created server          |
| server_ipv4     | Public IPv4 address of the server |
| server_ipv6     | Public IPv6 address of the server |
| firewall_id_ssh | ID of the default SSH firewall    |

## Limitations & Notes

- Only ext4 formatted volumes are supported
- SSL/TLS termination not included (consider using Traefik or similar)
- Volume backups must be managed separately (use Hetzner server backups instead)
