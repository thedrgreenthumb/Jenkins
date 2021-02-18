#!/bin/sh

BLOCK_DEVICE=${1}
BLOCK_DEVICE_SIZE=${2}
MOUNT_POINT=${3}
FORMAT_OPTIONS=${4}
MOUNT_OPTIONS=${5}
UNMOUNT_OPTIONS=${6}

mkdir_with_subdirs() # ${1} -> DIR_PATH, ${2} -> SUBDIR_NUM
{
	mkdir ${1}
	
	i=0
	while [ "${i}" -le "${2}" ]
	do
		mkdir ${1}/TEST_DIR_${i}
		if [ "$?" -ne "0" ]
		then
			echo "ERROR: in mkdir_with_subdirs(): i=${i}"
			exit 1
		fi
		i=$((i+1))
	done
}

rmdir_overfilled_partially() # ${1} DIR_PATH
{
	rm -r -f ${1}/TEST_DIR_6*
	if [ "$?" -ne "0" ]
	then
		echo "ERROR: rmdir: i=${i}"
		exit 1
	fi
	rm -r -f ${1}/TEST_DIR_7*
	if [ "$?" -ne "0" ]
	then
		echo "ERROR: rmdir: i=${i}"
		exit 1
	fi
	rm -r -f ${1}/TEST_DIR_8*
	if [ "$?" -ne "0" ]
	then
		echo "ERROR: rmdir: i=${i}"
		exit 1
	fi
	rm -r -f ${1}/TEST_DIR_9*
	if [ "$?" -ne "0" ]
	then
		echo "ERROR: rmdir: i=${i}"
		exit 1
	fi
}

./dev_add.sh "${BLOCK_DEVICE}" "${BLOCK_DEVICE_SIZE}"
./format.sh "${BLOCK_DEVICE}" "${FORMAT_OPTIONS}"
./mount.sh "${BLOCK_DEVICE}" "${MOUNT_POINT}" "${MOUNT_OPTIONS}"

mkdir_with_subdirs "${MOUNT_POINT}/TEST_DIR" 100000
rmdir_overfilled_partially "${MOUNT_POINT}/TEST_DIR"

./unmount.sh "${BLOCK_DEVICE}" "${UNMOUNT_OPTIONS}"
./check.sh "${BLOCK_DEVICE}"
./dev_remove.sh "${BLOCK_DEVICE}"
