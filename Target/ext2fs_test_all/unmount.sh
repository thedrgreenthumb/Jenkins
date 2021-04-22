#!/bin/sh

BLOCK_DEVICE=${1}
UNMOUNT_OPTIONS=${2}

if [ -z "$BLOCK_DEVICE" ]
then
	echo "=== ERROR: Block device was not set."
	exit 1
fi

# Wait some time to prevent "device busy" error
sleep 5

echo "=== UNMOUNT: unmount ${UNMOUNT_OPTIONS} ${BLOCK_DEVICE}"
umount ${UNMOUNT_OPTIONS} ${BLOCK_DEVICE} || exit 1
