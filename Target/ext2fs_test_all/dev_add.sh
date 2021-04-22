#!/bin/sh

BLOCK_DEVICE_SECTOR_SIZE="512"
BLOCK_DEVICE_SIZE_RESERVE=""
BLOCK_DEVICE_DD_BS="1M"
BLOCK_DEVICE_DD_COUNT="4096"

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
mdconfig -s ${BLOCK_DEVICE_SIZE} -S ${BLOCK_DEVICE_SECTOR_SIZE} -u 0 || exit 1

if [ ! -c "$BLOCK_DEVICE" ]; then
	echo "=== ERROR: Cannot create block device."
	ls /dev | grep md
	exit 1
fi

if [ "$BLOCK_DEVICE_SIZE" == "$BLOCK_DEVICE_SIZE_RESERVE" ]; then
	echo "Block device reserving..."
	dd if="/dev/zero" of="$BLOCK_DEVICE" \
	    bs="$BLOCK_DEVICE_DD_BS" count="$BLOCK_DEVICE_DD_COUNT"
fi
