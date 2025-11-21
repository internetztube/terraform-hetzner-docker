output "server_id" {
  value = hcloud_server.default.id
}

output "server_ipv4" {
  value = hcloud_server.default.ipv4_address
}

output "server_ipv6" {
  value = hcloud_server.default.ipv6_address
}

output "firewall_id_ssh" {
  value = hcloud_firewall.ssh.id
}
