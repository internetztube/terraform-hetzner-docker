#!/bin/bash

set -eu

# Runtime Environment: local via terraform

# CREATE_FINAL_SNAPSHOT=
# SERVER_NAME=
# SERVER_LOCATION=
# SERVER_ID=

if [ "${CREATE_FINAL_SNAPSHOT}" = "true" ]; then
  HCLOUD_TOKEN="${HCLOUD_TOKEN:-${TF_VAR_hcloud_token:-""}}"

  if [ -z "${HCLOUD_TOKEN}" ]; then
    echo "Error: Neither HCLOUD_TOKEN nor TF_VAR_hcloud_token is set."
    exit 1
  fi

  echo "Creating Final Snapshot ..."
  RESPONSE="$(
    curl -X POST \
      -H "Authorization: Bearer ${HCLOUD_TOKEN}" \
      -H "Content-Type: application/json" \
      -d "{\"description\": \"Final Snapshot for ${SERVER_NAME} / ${SERVER_LOCATION}\", \"labels\": {\"server-name\": \"${SERVER_NAME}\", \"server-id\": \"${SERVER_ID}\", \"server-location\": \"${SERVER_LOCATION}\"}, \"type\": \"snapshot\"}" \
      "https://api.hetzner.cloud/v1/servers/${SERVER_ID}/actions/create_image"
  )"
  echo "${RESPONSE}"

  # Extract the action.status using jq
  STATUS="$(echo "${RESPONSE}" | jq -r '.action.status')"

  # Check if the status is "running"
  if [ "${STATUS}" != "running" ]; then
    echo "Creating Final Snapshot failed!"
    echo "Action status is \"${STATUS}\". Aborting."
    exit 1
  else
    echo "Creating Final Snapshot ..."
  fi

else
  echo "Not creating final snapshot, since label is \"${CREATE_FINAL_SNAPSHOT}\""
fi
