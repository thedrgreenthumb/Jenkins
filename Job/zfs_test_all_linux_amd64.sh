#!/bin/bash

. ${JENKINS_START_HOME}/Config/${JOB_NAME}/config.sh
. ${JENKINS_START_HOME}/Config/${JOB_NAME}/test_cases_list.sh


TIMESTAMP="$(date +%Y-%m-%d.%H:%M:%S)"

echo "NOT IMPLEMENTED"
exit 0

JENKINS_TEST_CASES_PATH="${JENKINS_START_HOME}/Target/zfs_rze_tests"
TARGET_ZFS_SRC_PATH="$OPENZFS_TARGET_PATH"
TARGET_TEST_CASES_PATH="/home/user/zfs_test_rze"
TARGET_TEST_REPORT_PATH="/tmp/${JOB_NAME}_report_${TIMESTAMP}"
TEST_DIR="${TARGET_TEST_CASES_PATH}/native"

setup()
{
	echo "==== CLEANUP AND SETUP ===="
	echo "====== ${JOB_NAME} starting, TARGET=${TARGET}"
	ssh ${TARGET} "uname -a"

	echo "=== zfs module version"
	ssh -p ${PORT} ${TARGET} "dmesg | grep ZFS"

	echo "== copy tests data"
	ssh -p ${PORT} ${TARGET} "rm -r -f ${TARGET_TEST_CASES_PATH}"
	scp -P ${PORT} -r ${JENKINS_TEST_CASES_PATH} ${TARGET}:/${TARGET_TEST_CASES_PATH} || exit 1

	echo "== check zfs is clean"
	ZPOOLS=$(ssh -p ${PORT} ${TARGET} "zpool status | grep 'no pools available'" 2>&1)
	if [ -z "${ZPOOLS}" ]
	then
		echo "ERROR:zpool list is not empty"
		exit 1
	fi
}

run_testcases_all() # ${1} - test case name
{
	ssh -p ${PORT} ${TARGET} "cd ${TEST_DIR}; /bin/sh -e ${case} ${TARGET_TEST_REPORT_PATH} ${TARGET_ZFS_SRC_PATH}" || exit 1
}

#MAIN
setup

echo "================================================ run_testcases_all:"
for case in ${TESTCASES_ALL}
do
	echo "======================== CASE = $case"
	run_testcases_all "${case}"
done
