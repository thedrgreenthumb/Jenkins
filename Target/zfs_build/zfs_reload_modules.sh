#!/bin/bash

# export expected (ZFS_SOURCE_TARGET="/home/user/Sources/zfs")
if [ -z "$ZFS_SOURCE_TARGET" ]; then
	echo "Unknown zfs repo path"
	exit 1
fi

MOD0="/module/spl/spl.ko"
MOD1="/module/nvpair/znvpair.ko"
MOD2="/module/zcommon/zcommon.ko"
MOD3="/module/icp/icp.ko"
MOD4="/module/avl/zavl.ko"
MOD5="/module/lua/zlua.ko"
MOD6="/module/unicode/zunicode.ko"
MOD7="/module/zstd/zzstd.ko"
MOD8="/module/zfs/zfs.ko"

echo "Unload modules..."
rmmod ${ZFS_SOURCE_TARGET}/${MOD8}
rmmod ${ZFS_SOURCE_TARGET}/${MOD7}
rmmod ${ZFS_SOURCE_TARGET}/${MOD6}
rmmod ${ZFS_SOURCE_TARGET}/${MOD5}
rmmod ${ZFS_SOURCE_TARGET}/${MOD4}
rmmod ${ZFS_SOURCE_TARGET}/${MOD3}
rmmod ${ZFS_SOURCE_TARGET}/${MOD2}
rmmod ${ZFS_SOURCE_TARGET}/${MOD1}
rmmod ${ZFS_SOURCE_TARGET}/${MOD0}

echo "Load modules..."
insmod ${ZFS_SOURCE_TARGET}/${MOD0}
insmod ${ZFS_SOURCE_TARGET}/${MOD1}
insmod ${ZFS_SOURCE_TARGET}/${MOD2}
insmod ${ZFS_SOURCE_TARGET}/${MOD3}
insmod ${ZFS_SOURCE_TARGET}/${MOD4}
insmod ${ZFS_SOURCE_TARGET}/${MOD5}
insmod ${ZFS_SOURCE_TARGET}/${MOD6}
insmod ${ZFS_SOURCE_TARGET}/${MOD7}
insmod ${ZFS_SOURCE_TARGET}/${MOD8}