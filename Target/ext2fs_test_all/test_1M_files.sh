#!/bin/sh

BLOCK_DEVICE=${1}
BLOCK_DEVICE_SIZE=${2}
MOUNT_POINT=${3}
FORMAT_OPTIONS=${4}
MOUNT_OPTIONS=${5}
UNMOUNT_OPTIONS=${6}

#
# args:
# $1 = start index
# $2 = count
#
# notes:
# 250000 will fully fill 4G drive with 4k fs block size
#
touch_files()
{
	local i=$1
	local count=$2
	while [ "${i}" -le "$(($1+count))" ]
	do
		touch ${MOUNT_POINT}/FILE_${i}
		i=$((i+1))
	done
}

./dev_add.sh "${BLOCK_DEVICE}" "${BLOCK_DEVICE_SIZE}"
./format.sh "${BLOCK_DEVICE}" "${FORMAT_OPTIONS}"
./mount.sh "${BLOCK_DEVICE}" "${MOUNT_POINT}" "${MOUNT_OPTIONS}"

FILES_MAX="200000"
FILES_PER_CORE="$((FILES_MAX/NUM_CORES))"

for i in `seq $NUM_CORES`
do
	touch_files "$((i*FILES_MAX))" "$FILES_PER_CORE" &
done

wait

./unmount.sh "${BLOCK_DEVICE}" "${UNMOUNT_OPTIONS}"
./check.sh "${BLOCK_DEVICE}"
./dev_remove.sh "${BLOCK_DEVICE}"
