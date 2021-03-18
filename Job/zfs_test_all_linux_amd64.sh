#!/bin/bash

. ${JENKINS_START_HOME}/Config/${JOB_NAME}/config.sh
. ${JENKINS_START_HOME}/Config/${JOB_NAME}/test_cases_list.sh
. ${JENKINS_START_HOME}/Misc/misc.sh

JENKINS_TEST_CASES_PATH="${JENKINS_START_HOME}/Target/zfs_test_all"
TARGET_ZFS_SRC_PATH="$OPENZFS_TARGET_PATH"
TARGET_TEST_CASES_PATH="/home/user/zfs_test_rze"
TEST_TIMEOUT=12 # hours

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

	echo "== create tmp mount directory =="
	target_execute "mkdir $ZFS_FILEDIR"
	target_execute "sudo mount -t tmpfs -o rw tmpfs $ZFS_FILEDIR"

	echo "== skip zfs tests =="
	if [ ! -z "$TESTCASES_ZFS_SKIP" ]; then
		for test_path in $TESTCASES_ZFS_SKIP; do
			echo "SKIP ZFS TEST: $test_path"
			target_execute "rm -r -f $TARGET_ZFS_SRC_PATH/$test_path"
		done
	fi

	# TODO:
	# provide correct version of zfs module loaded, implement check to
	# verify loaded version is equal to commit in the repo
}

run_testcases_all() # ${1} - test case name
{
	target_execute "cd ${TARGET_TEST_CASES_PATH}; /bin/sh -e ${1} \
	    ${TARGET_ZFS_SRC_PATH} ${ZFS_FILEDIR}" $((TEST_TIMEOUT*60*60))
}

#MAIN
setup

echo "======================== run_testcases_all:"
for case in ${TESTCASES_ALL}
do
	echo "======================== CASE = $case"
	run_testcases_all "${case}"
done
