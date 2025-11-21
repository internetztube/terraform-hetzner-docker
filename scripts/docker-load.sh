#!/bin/bash

set -eu

# Runtime Environment: remote via terraform/ssh

for tar_file in /root/container-artifacts/*.tar; do
  if [ -f "${tar_file}" ]; then
    echo "Loading Docker image from: ${tar_file}"
    docker load -i "${tar_file}"
  fi
done

# Create volume folders
cd /root
yq -r "
  .services
  | to_entries[]
  | select(.value.user)
  | .value as \$svc
  | \$svc.user    as \$ug
  | (\$svc.volumes[]? | split(\":\")[0]) + \" \" + \$ug
" docker-compose.yml \
| while read -r host ug; do
  mkdir -p "$host"
  chown -R "$ug" "$host"
  chmod -R 775 "$host"
done

# Pull latest container images.
docker compose pull --ignore-pull-failures

# Restart!
systemctl restart docker-compose

# Delete old container images.
docker image prune -f
