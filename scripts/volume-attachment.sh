#!/bin/bash

set -eu

# Runtime Environment: remote via terraform/ssh

# VOLUME_ID=

DEVICE="/dev/disk/by-id/scsi-0HC_Volume_${VOLUME_ID}"
MOUNT_POINT="/root/volume"

# Wait for the device to be available
if [ ! -b "${DEVICE}" ]; then
  sleep 5
fi

# Wait for the device to be available
if [ ! -b "${DEVICE}" ]; then
  echo "Disk is not available!"
  exit 1
fi

# Check if the device is already mounted
if mountpoint -q "${MOUNT_POINT}"; then
  resize2fs -p "${DEVICE}"
  echo "Volume is already mounted at ${MOUNT_POINT}."
  exit 0
fi

# Format the volume if not already formatted
if ! blkid "${DEVICE}" >/dev/null 2>&1; then
  echo "Formatting ${DEVICE} with ext4 filesystem."
  mkfs.ext4 -F "${DEVICE}"
fi

# Create the mount point directory if it doesn't exist
mkdir -p "${MOUNT_POINT}"

# Mount the volume
echo "Mounting ${DEVICE} to ${MOUNT_POINT}."
mount -o discard,defaults "${DEVICE}" "${MOUNT_POINT}"

# Add volume to fstab if not already present
if ! grep -qs "${DEVICE}" /etc/fstab; then
  echo "Adding ${DEVICE} to /etc/fstab."
  echo "${DEVICE} ${MOUNT_POINT} ext4 discard,nofail,defaults 0 0" >> /etc/fstab
else
  echo "${DEVICE} is already present in /etc/fstab."
fi

echo "Volume ${DEVICE} mounted successfully at ${MOUNT_POINT}."
