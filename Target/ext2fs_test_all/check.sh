#!/bin/sh

BLOCK_DEVICE=${1}

if [ -z "$BLOCK_DEVICE" ]
then
	echo "=== ERROR: Block device was not set."
	exit 1
fi

echo "=== CHECK: e2fsck -f -n ext2fs ${BLOCK_DEVICE}"
e2fsck -f -n ${BLOCK_DEVICE} || exit 1
