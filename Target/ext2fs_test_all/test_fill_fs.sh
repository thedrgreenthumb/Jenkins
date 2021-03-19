#!/bin/sh

BLOCK_DEVICE=${1}
BLOCK_DEVICE_SIZE=${2}
MOUNT_POINT=${3}
FORMAT_OPTIONS=${4}
MOUNT_OPTIONS=${5}
UNMOUNT_OPTIONS=${6}

NUM_CORES=$(sysctl -a | grep hw.ncpu | awk -F ' ' '{print $2}')

./dev_add.sh "${BLOCK_DEVICE}" "${BLOCK_DEVICE_SIZE}"
./format.sh "${BLOCK_DEVICE}" "${FORMAT_OPTIONS}"
./mount.sh "${BLOCK_DEVICE}" "${MOUNT_POINT}" "${MOUNT_OPTIONS}"

for i in `seq $NUM_CORES`
do
	dd if=/dev/zero of="${MOUNT_POINT}"/FILE${i} bs=1m &
done

wait

./unmount.sh "${BLOCK_DEVICE}" "${UNMOUNT_OPTIONS}"
./check.sh "${BLOCK_DEVICE}"
./dev_remove.sh "${BLOCK_DEVICE}"
