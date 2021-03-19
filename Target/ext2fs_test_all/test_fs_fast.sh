#!/bin/sh


#
# BAD SEEDS:
# 2124: mke2fs -F -b 2048 -O huge_file -O dir_nlink -O uninit_bg -O extents /dev/md0
# 6136: mke2fs -F -b 1024 -O huge_file -O dir_nlink -O uninit_bg -O extents -O 64bit /dev/md0

BLOCK_DEVICE=${1}
BLOCK_DEVICE_SIZE=${2}
MOUNT_POINT=${3}
FORMAT_OPTIONS=${4}
MOUNT_OPTIONS=${5}
UNMOUNT_OPTIONS=${6}

NUM_CORES=$(sysctl -a | grep hw.ncpu | awk -F ' ' '{print $2}')

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
		/bin/sh -ce "cd ${MOUNT_POINT} && ./fsx -S ${SEED} -N ${NUM_OPS} ./TEST_FILE0_${i}" &
		pid_list=$pid_list" "$!

		/bin/sh -ce "cd ${MOUNT_POINT} && ./fsx -S ${SEED} -b 1430000 -c 9999 -O -o 7000 -l 7000 -W -N ${NUM_OPS} ./TEST_FILE1_${i}" &
		pid_list=$pid_list" "$!

		/bin/sh -ce "cd ${MOUNT_POINT} && ./fsx -S ${SEED} -o 10000 -l 10000 -N ${NUM_OPS} ./TEST_FILE2_${i}" &
		pid_list=$pid_list" "$!

		/bin/sh -ce "cd ${MOUNT_POINT} && ./fsx -S ${SEED} -b 1430000 -c 9999 -O -o 7000 -l 7000 -N ${NUM_OPS} ./TEST_FILE3_${i}" &
		pid_list=$pid_list" "$!

		/bin/sh -ce "cd ${MOUNT_POINT} && ./fsx -S ${SEED} -b 1430000 -c 9999 -O -o 7000 -l 7000 -N ${NUM_OPS} ./TEST_FILE4_${i}" &
		pid_list=$pid_list" "$!

		/bin/sh -ce "cd ${MOUNT_POINT} && ./fsx -S ${SEED} -b 1190000 -o 10000 -l 10000 -N ${NUM_OPS}  ./TEST_FILE5_${i}" &
		pid_list=$pid_list" "$!

		/bin/sh -ce "cd ${MOUNT_POINT} && ./fsx -S ${SEED} -b 1199000 -o 512 -l 512 -R -W -N ${NUM_OPS} ./TEST_FILE6_${i}" &
		pid_list=$pid_list" "$!

		/bin/sh -ce "cd ${MOUNT_POINT} && ./fsx -S ${SEED} -b 448000 -o 1023 -l 1023 -N ${NUM_OPS} ./TEST_FILE7_${i}" &
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

run_fstorture()
{
	local NUM_OPS=100

	if [ ! -f ${MOUNT_POINT}/fstorture ]; then
		echo "Cannot find binary test FAIL"
		exit 1
	fi

	mkdir ${MOUNT_POINT}/root0 ${MOUNT_POINT}/root1 
	/bin/sh -ce "cd ${MOUNT_POINT} && ./fstorture root0 root1 $NUM_CORES -c ${NUM_OPS}"

	sleep 3
}


# MAIN
./dev_add.sh "${BLOCK_DEVICE}" "${BLOCK_DEVICE_SIZE}"
./format.sh "${BLOCK_DEVICE}" "${FORMAT_OPTIONS}"
./mount.sh "${BLOCK_DEVICE}" "${MOUNT_POINT}" "${MOUNT_OPTIONS}"

echo "Copy test binaries..."
cp /root/Sources/fstools/src/fsx/fsx "${MOUNT_POINT}"/ || exit 1
cp /root/Sources/fstools/src/fstorture/fstorture "${MOUNT_POINT}"/ || exit 1

run_fsx
run_fstorture

./unmount.sh "${BLOCK_DEVICE}" "${UNMOUNT_OPTIONS}"
./check.sh "${BLOCK_DEVICE}"
./dev_remove.sh "${BLOCK_DEVICE}"
