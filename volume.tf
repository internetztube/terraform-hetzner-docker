resource "hcloud_volume_attachment" "default" {
  count     = var.volume != null ? 1 : 0
  server_id = hcloud_server.default.id
  volume_id = var.volume.id
  automount = false
}

resource "null_resource" "volume_attachment" {
  count = var.volume != null ? 1 : 0

  depends_on = [
    hcloud_volume_attachment.default
  ]

  triggers = {
    always_run = "${timestamp()}"
  }

  connection {
    type        = "ssh"
    user        = "root"
    private_key = var.ssh_private_key
    host        = hcloud_server.default.ipv4_address
    timeout     = "5m"
  }

  provisioner "file" {
    source      = "${path.module}/scripts/volume-attachment.sh"
    destination = "/root/volume-attachment.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "VOLUME_ID=\"${var.volume.id}\" sh /root/volume-attachment.sh"
    ]
  }
}
