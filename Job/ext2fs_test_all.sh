#!/bin/bash

. ${JENKINS_START_HOME}/Config/${JOB_NAME}/config.sh
. ${JENKINS_START_HOME}/Config/${JOB_NAME}/test_cases_list.sh

BLOCK_DEVICE="/dev/md0"
BLOCK_DEVICE_SIZE="4G"
BLOCK_DEVICE_SIZE_LARGE="20T"
MOUNT_POINT="/mnt"

BLOCK_SIZES="1024 2048 4096"

# 4GB drive
# mkfs.ext2 : ext_attr resize_inode dir_index filetype sparse_super large_file
# mkfs.ext3 : has_journal ext_attr resize_inode dir_index filetype sparse_super large_file
# mkfs.ext4 : has_journal ext_attr resize_inode dir_index filetype extent 64bit flex_bg sparse_super large_file huge_file dir_nlink extra_isize metadata_csum

FEATURES_0="-O sparse_super,large_file,filetype,resize_inode"
FEATURES_1="-O metadata_csum"
FEATURES_2="-O huge_file -O dir_nlink"
FEATURES_3="-O huge_file -O dir_nlink -O uninit_bg"
FEATURES_4="-O huge_file -O dir_nlink -O uninit_bg -O extents"
FEATURES_5="-O huge_file -O dir_nlink -O uninit_bg -O extents -O 64bit"
FEATURES_6="-O huge_file -O dir_nlink -O uninit_bg -O ^resize_inode -O flex_bg"
FEATURES_7="-O huge_file -O dir_nlink -O uninit_bg -O ^resize_inode -O meta_bg"
FEATURES_8="-O huge_file -O dir_nlink -O uninit_bg -O ^resize_inode -O meta_bg -O flex_bg"
FEATURES_9="-O huge_file -O dir_nlink -O metadata_csum"
FEATURES_10="-O huge_file -O dir_nlink -O metadata_csum -O ^resize_inode -O meta_bg"
FEATURES_11="-O huge_file -O dir_nlink -O metadata_csum -O ^resize_inode -O flex_bg"
FEATURES_12="-O huge_file -O dir_nlink -O metadata_csum -O ^resize_inode -O meta_bg -O flex_bg"
FEATURES_13="-O huge_file -O dir_nlink -O uninit_bg -O extents"
FEATURES_14="" # "-O huge_file -O dir_nlink -O uninit_bg -O extents -O ^resize_inode -O meta_bg" could cause fsx e2fsck errors on 1k block size
FEATURES_15="-O huge_file -O dir_nlink -O uninit_bg -O extents -O ^resize_inode -O flex_bg"
FEATURES_16="" #"-O huge_file -O dir_nlink -O uninit_bg -O extents -O ^resize_inode -O flex_bg -O meta_bg" errors seed 5844 fsx 4k block fs_fast
FEATURES_17="-O extents -O 64bit -O metadata_csum"      #"-O huge_file -O dir_nlink -O uninit_bg -O extents -O metadata_csum" # could cause fsx e2fsck errors on 4k block
FEATURES_18="-O huge_file -O dir_nlink -O extents -O 64bit"
FEATURES_19="-O huge_file -O dir_nlink -O extents -O 64bit -O metadata_csum"
FEATURES_20="" # "-O huge_file -O dir_nlink -O extents -O 64bit -O metadata_csum -O ^resize_inode -O flex_bg" could cause fsx e2fsck errors on 1k block size
FEATURES_21="-O huge_file -O dir_nlink -O extents -O 64bit -O metadata_csum -O ^resize_inode -O meta_bg"
FEATURES_22="" # "-O huge_file -O dir_nlink -O extents -O 64bit -O metadata_csum -O ^resize_inode -O flex_bg -O meta_bg" could cause fsx e2fsck errors on 1k block size

FEATURES_EXT2="-O sparse_super,large_file,filetype,resize_inode,dir_index"
FEATURES_EXT3="-O sparse_super,large_file,filetype,resize_inode,dir_index,ext_attr,has_journal,extent"
FEATURES_EXT4="-O sparse_super,large_file,filetype,resize_inode,dir_index,ext_attr,has_journal,extent,huge_file,flex_bg,metadata_csum,64bit,dir_nlink,extra_isize"

declare -a FEATURES_LIST_ALL=("${FEATURE_EXT2} "${FEATURE_EXT3}" ${FEATURE_EXT4}" \
	"${FEATURES_0}" "${FEATURES_1}" "${FEATURES_2}" "${FEATURES_3}" \
	"${FEATURES_4}" "${FEATURES_5}" "${FEATURES_6}" "${FEATURES_7}" "${FEATURES_8}" \
	"${FEATURES_9}" "${FEATURES_10}" "${FEATURES_11}" "${FEATURES_12}" "${FEATURES_13}" \
	"${FEATURES_14}" "${FEATURES_15}" "${FEATURES_16}" "${FEATURES_17}" "${FEATURES_18}" \
	"${FEATURES_19}" "${FEATURES_20}" "${FEATURES_21}" "${FEATURES_22}")

declare -a FEATURES_LIST_EXT_VERSION=("${FEATURES_EXT2}" "${FEATURES_EXT3}" "${FEATURES_EXT4}" )

run_testcases_all() # ${1} - test case name
{
	CASE=${1}
	for block_size in ${BLOCK_SIZES}
	do
		for features in "${FEATURES_LIST_ALL[@]}"
		do
			FORMAT_OPTIONS="-b $block_size $features"
			ssh ${TARGET} "cd ${TEST_CASES_PATH}; /bin/sh -e ${case} \"${BLOCK_DEVICE}\" \"${BLOCK_DEVICE_SIZE}\" \"${MOUNT_POINT}\" \"${FORMAT_OPTIONS}\"" || exit 1
		done
	done
}

run_testcases_all_versions() # ${1} - test case name
{
	CASE=${1}
	for block_size in ${BLOCK_SIZES}
	do
		for features in "${FEATURES_LIST_EXT_VERSION[@]}"
		do
			FORMAT_OPTIONS="-b $block_size $features"
			ssh ${TARGET} "cd ${TEST_CASES_PATH}; /bin/sh -e ${case} \"${BLOCK_DEVICE}\" \"${BLOCK_DEVICE_SIZE}\" \"${MOUNT_POINT}\" \"${FORMAT_OPTIONS}\"" || exit 1
		done
	done
}

run_testcases_all_versions_4k() # ${1} - test case name
{
	for features in "${FEATURES_LIST_EXT_VERSION[@]}"
	do
		FORMAT_OPTIONS="-b 4096 $features"
		ssh ${TARGET} "cd ${TEST_CASES_PATH}; /bin/sh -e ${case} \"${BLOCK_DEVICE}\" \"${BLOCK_DEVICE_SIZE}\" \"${MOUNT_POINT}\" \"${FORMAT_OPTIONS}\"" || exit 1
	done
}

run_testcases_version_ext4_4k() # ${1} - test case name
{
	FORMAT_OPTIONS="-b 4096 ${FEATURES_EXT4}"
	ssh ${TARGET} "cd ${TEST_CASES_PATH}; /bin/sh -e ${case} \"${BLOCK_DEVICE}\" \"${BLOCK_DEVICE_SIZE}\" \"${MOUNT_POINT}\" \"${FORMAT_OPTIONS}\"" || exit 1
}

run_testcases_version_ext4_4k_large_dev() # ${1} - test case name
{
	FORMAT_OPTIONS="-b 4096 ${FEATURES_EXT4}"
	ssh ${TARGET} "cd ${TEST_CASES_PATH}; /bin/sh -e ${case} \"${BLOCK_DEVICE}\" \"${BLOCK_DEVICE_SIZE_LARGE}\" \"${MOUNT_POINT}\" \"${FORMAT_OPTIONS}\"" || exit 1
}

setup()
{
	echo "=== CLEANUP AND SETUP"
	ssh ${TARGET} "rm -r -f ${TEST_CASES_PATH}"
	scp -r /home/drgreenthumb/Jenkins/Target/ext2fs_test_all ${TARGET}:/root/${JOB_NAME} || exit 1
	ssh ${TARGET} "umount -f ${BLOCK_DEVICE}"
	ssh ${TARGET} "mdconfig -d -u 0"
}

#MAIN
echo "====== ${JOB_NAME} starting, TARGET=${TARGET}"
ssh ${TARGET} "uname -a"

setup

echo "================================================ run_testcases_all:"
for case in ${TESTCASES_ALL}
do
	echo "======================== CASE = $case"
	run_testcases_all "${case}"
done

echo "================================================ run_testcases_all_versions:"
for case in ${TESTCASES_ALL_VERSIONS}
do
	echo "======================== CASE = $case"
	run_testcases_all_versions "${case}"
done

echo "================================================ run_testcases_all_versions_4k:"
for case in ${TESTCASES_ALL_VERSIONS_4K}
do
	echo "======================== CASE = $case"
	run_testcases_all_versions_4k "${case}"
done

echo "================================================ run_testcases_version_ext4_4k:"
for case in ${TESTCASES_VERSION_EXT4_4K}
do
	echo "======================== CASE = $case"
	run_testcases_version_ext4_4k "${case}"
done

echo "================================================ run_testcases_version_ext4_4k_large_dev:"
for case in ${TESTCASES_VERSION_EXT4_4K_LARGE_DEV}
do
	echo "======================== CASE = $case"
	run_testcases_version_ext4_4k_large_dev "${case}"
done