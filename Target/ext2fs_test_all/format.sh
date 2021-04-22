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

# echo "=== SET SPECIAL GUID:"
# yes | tune2fs -U f0acce91-a416-474c-8a8c-43f3ed376867 /dev/md0 || exit 1
