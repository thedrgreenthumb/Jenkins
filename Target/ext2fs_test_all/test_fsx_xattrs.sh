#!/bin/sh

BLOCK_DEVICE=${1}
BLOCK_DEVICE_SIZE=${2}
MOUNT_POINT=${3}
FORMAT_OPTIONS=${4}
MOUNT_OPTIONS=${5}
UNMOUNT_OPTIONS=${6}

run_fsx()
{
	local pid_list=""
	local check_errors="OK"
	local NUM_OPS=1000
	local SEED=0


	if [ ! -f ${MOUNT_POINT}/fsx ]; then
		echo "Cannot find binary test FAIL"
		exit 1
	fi

	local loops=$((NUM_CORES/8))
	if [ "$loops" -eq "0" ]; then
		loops=1
	fi

	for i in `seq $loops`
	do
		/bin/sh -ce "cd ${MOUNT_POINT} && ./fsx -S ${SEED} -e 512 -N ${NUM_OPS} ./TEST_FILE0_${i}" &
		pid_list=$pid_list" "$!

		/bin/sh -ce "cd ${MOUNT_POINT} && ./fsx -S ${SEED} -e 687 -N ${NUM_OPS} ./TEST_FILE1_${i}" &
		pid_list=$pid_list" "$!

		/bin/sh -ce "cd ${MOUNT_POINT} && ./fsx -S ${SEED} -e 900 -N ${NUM_OPS} ./TEST_FILE2_${i}" &
		pid_list=$pid_list" "$!

		/bin/sh -ce "cd ${MOUNT_POINT} && ./fsx -S ${SEED} -e 24 -N ${NUM_OPS} ./TEST_FILE3_${i}" &
		pid_list=$pid_list" "$!

		/bin/sh -ce "cd ${MOUNT_POINT} && ./fsx -S ${SEED} -e 127 -N ${NUM_OPS} ./TEST_FILE4_${i}" &
		pid_list=$pid_list" "$!

		/bin/sh -ce "cd ${MOUNT_POINT} && ./fsx -S ${SEED} -e 254 -N ${NUM_OPS}  ./TEST_FILE5_${i}" &
		pid_list=$pid_list" "$!

		/bin/sh -ce "cd ${MOUNT_POINT} && ./fsx -S ${SEED} -e 319 -N ${NUM_OPS} ./TEST_FILE6_${i}" &
		pid_list=$pid_list" "$!

		/bin/sh -ce "cd ${MOUNT_POINT} && ./fsx -S ${SEED} -e 876 -N ${NUM_OPS} ./TEST_FILE7_${i}" &
		pid_list=$pid_list" "$!
	done

	for a in ${pid_list}
	do
		wait ${a} || check_errors="ERROR"
	done

	if [ "OK" != "${check_errors}" ]
	then
		echo "FSX test ERROR"
		exit 1
	else
		echo "FSX test PASS"
	fi

	sleep 3
}

# MAIN
./dev_add.sh "${BLOCK_DEVICE}" "${BLOCK_DEVICE_SIZE}"
./format.sh "${BLOCK_DEVICE}" "${FORMAT_OPTIONS}"
./mount.sh "${BLOCK_DEVICE}" "${MOUNT_POINT}" "${MOUNT_OPTIONS}"

echo "Copy test binaries..."
cp /root/Sources/fstools/src/fsx/fsx "${MOUNT_POINT}"/ || exit 1

run_fsx

./unmount.sh "${BLOCK_DEVICE}" "${UNMOUNT_OPTIONS}"
./check.sh "${BLOCK_DEVICE}"
./dev_remove.sh "${BLOCK_DEVICE}"
