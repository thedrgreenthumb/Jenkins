#!/bin/sh

BLOCK_DEVICE=${1}
BLOCK_DEVICE_SIZE=${2}
MOUNT_POINT=${3}
FORMAT_OPTIONS=${4}
MOUNT_OPTIONS=${5}
UNMOUNT_OPTIONS=${6}

./dev_add.sh "${BLOCK_DEVICE}" "${BLOCK_DEVICE_SIZE}"
./format.sh "${BLOCK_DEVICE}" "${FORMAT_OPTIONS}"
./mount.sh "${BLOCK_DEVICE}" "${MOUNT_POINT}" "${MOUNT_OPTIONS}"


dd if=/dev/urandom of="${MOUNT_POINT}"/FILE0 &
dd if=/dev/urandom of="${MOUNT_POINT}"/FILE1 &
dd if=/dev/urandom of="${MOUNT_POINT}"/FILE2 &
dd if=/dev/urandom of="${MOUNT_POINT}"/FILE3 &

wait

./unmount.sh "${BLOCK_DEVICE}" "${UNMOUNT_OPTIONS}"
./check.sh "${BLOCK_DEVICE}"
./dev_remove.sh "${BLOCK_DEVICE}"
