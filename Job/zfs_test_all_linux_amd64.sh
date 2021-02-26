#!/bin/bash

. ${JENKINS_START_HOME}/Config/${JOB_NAME}/config.sh
. ${JENKINS_START_HOME}/Config/${JOB_NAME}/test_cases_list.sh
. ${JENKINS_START_HOME}/Misc/misc.sh

JENKINS_TEST_CASES_PATH="${JENKINS_START_HOME}/Target/zfs_test_all"
TARGET_ZFS_SRC_PATH="$OPENZFS_TARGET_PATH"
TARGET_TEST_CASES_PATH="/home/user/zfs_test_rze"
TEST_TIMEOUT=6 # hours

setup()
{
	echo "==== CLEANUP AND SETUP ===="
	echo "====== ${JOB_NAME} starting, TARGET=${TARGET}"
	target_info

	echo "=== zfs module version"
	target_execute "dmesg | grep ZFS"

	echo "== copy tests data =="
	target_execute "rm -r -f ${TARGET_TEST_CASES_PATH}"
	target_scp_to "${JENKINS_TEST_CASES_PATH}" "${TARGET_TEST_CASES_PATH}" 
}

run_testcases_all() # ${1} - test case name
{
	target_execute "cd ${TARGET_TEST_CASES_PATH}; /bin/sh -e ${1} ${TARGET_ZFS_SRC_PATH}" $((TEST_TIMEOUT*60*60))
}

#MAIN
setup

echo "======================== run_testcases_all:"
for case in ${TESTCASES_ALL}
do
	echo "======================== CASE = $case"
	run_testcases_all "${case}"
done
