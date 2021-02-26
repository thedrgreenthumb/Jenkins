#!/bin/sh

#
# Run scripts/zfs-tests.sh zfs tests.
#

OPENZFS_TARGET_PATH=${1}

echo "========= ZFS TEST ALL ========="
echo "target zfs dir: $OPENZFS_TARGET_PATH"

cd $OPENZFS_TARGET_PATH && ./scripts/zfs-tests.sh