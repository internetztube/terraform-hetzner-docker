resource "hcloud_server" "default" {
  name         = var.name
  server_type  = var.server_type
  image        = "ubuntu-24.04"
  location     = var.location
  firewall_ids = concat(var.firewall_ids, [hcloud_firewall.ssh.id])
  keep_disk    = var.keep_disk
  backups      = var.backups

  # ipv4 needs to be enabled in order to make ipv4 floating ip work.
  public_net {
    ipv6_enabled = true
    ipv4_enabled = true
  }

  labels = {
    tf_create_final_snapshot = var.create_final_snapshot
  }

  ssh_keys = [var.ssh_key_id]

  # Final Snapshot
  provisioner "local-exec" {
    when        = destroy
    interpreter = ["/bin/bash", "-c"]
    environment = {
      SERVER_ID             = self.id
      SERVER_NAME           = self.name
      SERVER_LOCATION       = self.location
      CREATE_FINAL_SNAPSHOT = lookup(self.labels, "tf_create_final_snapshot", "false")
    }
    command = "sh ${path.module}/scripts/server-final-snapshot.sh"
  }
}

# We're using remote scripts in favor of cloud-init.yml, since with every cloud-init.yml change the server gets recreated.
# With remote scripts, we're more flexible.
resource "null_resource" "host_dependency_basic" {
  triggers = {
    last_update = "2025-05-09"
  }

  depends_on = [
    hcloud_server.default
  ]

  provisioner "remote-exec" {
    inline = [
      <<EOF
        apt-get update
        apt-get install -y ca-certificates unattended-upgrades curl gnupg unzip yq htop
      EOF
    ]

    connection {
      type        = "ssh"
      user        = "root"
      private_key = var.ssh_private_key
      host        = hcloud_server.default.ipv4_address
      timeout     = "5m"
    }
  }
}

resource "null_resource" "host_dependency_aws_cli" {
  triggers = {
    last_update = "2025-03-15"
  }

  depends_on = [
    null_resource.host_dependency_basic
  ]

  provisioner "remote-exec" {
    inline = [
      <<EOF
        curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
        unzip awscliv2.zip
        ./aws/install
        rm -f awscliv2.zip
      EOF
    ]

    connection {
      type        = "ssh"
      user        = "root"
      private_key = var.ssh_private_key
      host        = hcloud_server.default.ipv4_address
      timeout     = "5m"
    }
  }
}

resource "null_resource" "host_dependency_docker" {
  triggers = {
    last_update = "2025-05-11"
  }

  depends_on = [
    null_resource.host_dependency_aws_cli
  ]

  provisioner "remote-exec" {
    inline = [
      <<EOF
        # Clean install
        apt-get remove -y docker-ce                || true
        apt-get remove -y docker-ce-cli            || true
        apt-get remove -y containerd.io            || true
        apt-get remove -y docker-buildx-plugin     || true
        apt-get remove -y docker-compose-plugin    || true

        # Allow internet access
        echo "net.ipv4.ip_forward=1" >> /etc/sysctl.d/enable-ip-forward.conf

        # Add Docker's official GPG key
        install -m 0755 -d /etc/apt/keyrings
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
        chmod a+r /etc/apt/keyrings/docker.gpg

        # Set up Docker repository
        echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

        # Install Docker Engine, CLI, Containerd, Docker Compose
        apt-get update
        apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
      EOF
    ]

    connection {
      type        = "ssh"
      user        = "root"
      private_key = var.ssh_private_key
      host        = hcloud_server.default.ipv4_address
      timeout     = "5m"
    }
  }
}

resource "null_resource" "server_ready" {
  triggers = {
    always = timestamp()
  }

  depends_on = [
    null_resource.host_dependency_basic,
    null_resource.host_dependency_aws_cli,
    null_resource.host_dependency_docker
  ]
}
