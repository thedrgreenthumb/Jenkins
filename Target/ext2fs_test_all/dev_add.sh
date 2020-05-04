#!/bin/sh

BLOCK_DEVICE=${1}
BLOCK_DEVICE_SIZE=${2}

if [ -z "$BLOCK_DEVICE" ]
then
	echo "=== ERROR: Block device was not set."
	exit 1
fi

if [ -z "$BLOCK_DEVICE_SIZE" ]
then
	echo "=== ERROR: Block device size was not set."
	exit 1
fi

echo "=== ADD BLOCK DEVICE: ${BLOCK_DEVICE}"
mdconfig -s ${BLOCK_DEVICE_SIZE} -u 0 || exit 1
