#!/bin/bash

set -eu

# Runtime Environment: remote via terraform/ssh

# IP_ADDRESS=
# IP_CIDR=

rm -rf /etc/netplan/60-floating-ip.yaml

echo "
network:
  version: 2
  renderer: networkd
  ethernets:
    eth0:
      addresses:
      - ${IP_ADDRESS}/${IP_CIDR}
" > /etc/netplan/60-floating-ip.yaml

chmod 600 /etc/netplan/60-floating-ip.yaml
netplan apply
