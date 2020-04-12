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

i=0
count=200000 # 250000 will fully fill 4G drive with 4k fs block size
while [ "${i}" -le "${count}" ]
do
	touch ${MOUNT_POINT}/FILE_${i}
	i=$((i+1))
done

sleep 5

./unmount.sh "${BLOCK_DEVICE}" "${UNMOUNT_OPTIONS}"
./check.sh "${BLOCK_DEVICE}"
./dev_remove.sh "${BLOCK_DEVICE}"
