resource "hcloud_floating_ip_assignment" "default" {
  count          = var.floating_ip != null ? 1 : 0
  floating_ip_id = var.floating_ip.id
  server_id      = hcloud_server.default.id
}

resource "null_resource" "floating_ip_attachment" {
  count = var.floating_ip != null ? 1 : 0

  depends_on = [
    hcloud_floating_ip_assignment.default
  ]

  triggers = {
    always_run = timestamp()
  }

  connection {
    type        = "ssh"
    user        = "root"
    private_key = var.ssh_private_key
    host        = hcloud_server.default.ipv4_address
    timeout     = "5m"
  }

  # Upload floating-ip-attachment.sh file.
  provisioner "file" {
    source      = "${path.module}/scripts/floating-ip-attachment.sh"
    destination = "/root/floating-ip-attachment.sh"
  }

  # Attach floating ip.
  provisioner "remote-exec" {
    inline = [
      "IP_ADDRESS=\"${var.floating_ip.ip_address}\" IP_CIDR=\"${var.floating_ip.type == "ipv4" ? "32" : "64"}\" sh /root/floating-ip-attachment.sh"
    ]
  }
}