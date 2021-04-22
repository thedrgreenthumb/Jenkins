#!/bin/sh

BLOCK_DEVICE=${1}
MOUNT_POINT=${2}
MOUNT_OPTIONS=${3}

if [ -z "$BLOCK_DEVICE" ]
then
	echo "=== ERROR: Block device was not set."
	exit 1
fi

if [ -z "$MOUNT_POINT" ]
then
	echo "=== ERROR: Mount point was not set."
	exit 1
fi

echo "=== MOUNT: mount -t ext2fs ${MOUNT_OPTIONS} ${BLOCK_DEVICE} ${MOUNT_POINT}"
mount -t ext2fs ${MOUNT_OPTIONS} ${BLOCK_DEVICE} ${MOUNT_POINT} || exit 1
