#!/bin/sh

BLOCK_DEVICE=${1}
BLOCK_DEVICE_SIZE=${2}
MOUNT_POINT=${3}
FORMAT_OPTIONS=${4}
MOUNT_OPTIONS=${5}
UNMOUNT_OPTIONS=${6}

TRUNCATE_RESULT_LINES="365"

./dev_add.sh "${BLOCK_DEVICE}" "${BLOCK_DEVICE_SIZE}"
./format.sh "${BLOCK_DEVICE}" "${FORMAT_OPTIONS}"
./mount.sh "${BLOCK_DEVICE}" "${MOUNT_POINT}" "${MOUNT_OPTIONS}"

echo "Copy pjdfstest..."
cp -r /root/Sources/pjdfstest ${MOUNT_POINT}

echo "Start test..."
/bin/sh -c "cd ${MOUNT_POINT} && prove -r ./pjdfstest/tests | tee ./test.data"
/bin/sh -c "cd ${MOUNT_POINT} && head -${TRUNCATE_RESULT_LINES} ./test.data > actual.data"

echo "Compare results..."
/bin/sh -c "cd ${MOUNT_POINT} && head -${TRUNCATE_RESULT_LINES} /root/Sources/pjdfstest/expected.data > ./expected.data"
EXPECTED_MD5=$(md5 /root/Sources/pjdfstest/expected.data | awk '{print $4}')
ACTUAL_MD5=$(md5 ${MOUNT_POINT}/actual.data | awk '{print $4}')

if [ "${EXPECTED_MD5}" != "${ACTUAL_MD5}" ]
then
	echo "=== ERROR: bad md5"
	exit 1
fi

./unmount.sh "${BLOCK_DEVICE}" "${UNMOUNT_OPTIONS}"
./check.sh "${BLOCK_DEVICE}"
./dev_remove.sh "${BLOCK_DEVICE}"
