#!/bin/sh

BLOCK_DEVICE=${1}
FORMAT_OPTIONS=${2}

if [ -z "$BLOCK_DEVICE" ]
then
	echo "=== ERROR: Block device was not set."
	exit 1
fi

echo "=== FORMAT: mke2fs -F ${FORMAT_OPTIONS} ${BLOCK_DEVICE}"
mke2fs -F ${FORMAT_OPTIONS} ${BLOCK_DEVICE} || exit 1
