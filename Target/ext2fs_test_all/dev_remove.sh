#!/bin/sh

BLOCK_DEVICE=${1}

if [ -z "$BLOCK_DEVICE" ]
then
	echo "=== ERROR: Block device was not set."
	exit 1
fi

echo "=== REMOVE BLOCK DEVICE: ${BLOCK_DEVICE}"
mdconfig -d -u 0 || exit 1