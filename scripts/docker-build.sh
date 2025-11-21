#!/bin/bash

set -eu

# Runtime Environment: local via terraform

# CONTAINERS_FOLDER_PATH=
# CONTAINERS_ARTIFACTS_FOLDER_PATH=

cd "${CONTAINERS_FOLDER_PATH}" || exit 1

mkdir -p "${CONTAINERS_ARTIFACTS_FOLDER_PATH}"

for dir in */; do
  CONTAINER_NAME="$(basename "${dir}")"
  export CONTAINER_NAME
  CONTAINER_TAG="${CONTAINER_NAME}:latest"
  export CONTAINER_TAG

  cd "${CONTAINERS_FOLDER_PATH}/${CONTAINER_NAME}" || exit 1

  if [ -f "docker-build.sh" ]; then
    echo "${CONTAINER_NAME}: found custom build script"
    echo "=============================="
    sh docker-build.sh
    echo "=============================="
  else
    echo "${CONTAINER_NAME}: use default build script"
    docker build -t "${CONTAINER_TAG}" -f Dockerfile .
  fi

  cd "${CONTAINERS_FOLDER_PATH}/${CONTAINER_NAME}" || exit 1
  docker save -o "${CONTAINERS_ARTIFACTS_FOLDER_PATH}/${CONTAINER_NAME}.tar" "${CONTAINER_TAG}"
done
