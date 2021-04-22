#!/bin/sh

#
# Run scripts/zfs-tests.sh zfs tests.
#

OPENZFS_TARGET_PATH=${1}
ZFS_FILEDIR=${2}

echo "========= ZFS TEST ALL ========="
echo "target zfs dir: $OPENZFS_TARGET_PATH, target zfs test dir: $ZFS_FILEDIR"

cd $OPENZFS_TARGET_PATH && ./scripts/zfs-tests.sh