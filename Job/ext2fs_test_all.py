import os
import sys
import time
import tempfile

job_name = os.environ['JOB_NAME']
skip_source_update = os.environ.get('SKIP_SOURCE_UPDATE')

repo_url = os.environ.get('REPO_URL')
repo_branch = os.environ.get('REPO_BRANCH')
repo_commit_id = os.environ.get('COMMIT_ID')

jenkins_path = os.path.join(os.path.realpath(os.path.dirname(__file__)), '..')
config_path = os.path.join(jenkins_path, 'Config', job_name)
misc_path = os.path.join(jenkins_path, 'Misc')
target_path = os.path.join(jenkins_path, 'Target')

sys.path.append(config_path)
sys.path.append(misc_path)

from config import ConfigParams
from target import Target

tgt = Target(ConfigParams())

tgt.vm_connect()

required_ram = 8192
required_vcpus = 4
tgt.set_memory(required_ram)
tgt.set_vcpus(required_vcpus)
print("Set ram {} and vcpus {}".format(required_ram, required_vcpus))

tgt.vm_start()
tgt.ssh_connect()

class TargetConfig:
	dev="/dev/md0"
	dev_size="4G"
	dev_large_size="20T"
	mp="/mnt"
	fs_blk_sizes=[ "1024", "2048",  "4096" ]
	testcases_path="/root/ext2fs_test_all"

tgtcfg = TargetConfig()

ext2_fs_features = [
	"-O sparse_super,large_file,filetype,resize_inode,dir_index"
]

ext3_fs_features = [
	"-O sparse_super,large_file,filetype,resize_inode,dir_index,ext_attr,\
has_journal,extent"
]

ext4_fs_features = [
	"-O sparse_super,large_file,filetype,resize_inode,dir_index,ext_attr,\
has_journal,extent,huge_file,flex_bg,metadata_csum,64bit,dir_nlink,extra_isize"
]

fs_ext_ver_features = ext2_fs_features + ext3_fs_features + ext4_fs_features

all_fs_features = [
	"-O sparse_super,large_file,filetype,resize_inode",
	"-O metadata_csum",
	"-O huge_file -O dir_nlink",
	"-O huge_file -O dir_nlink -O uninit_bg",
	"-O huge_file -O dir_nlink -O uninit_bg -O extents",
	"-O huge_file -O dir_nlink -O uninit_bg -O extents -O 64bit",
	"-O huge_file -O dir_nlink -O uninit_bg -O ^resize_inode -O flex_bg",
	"-O huge_file -O dir_nlink -O uninit_bg -O ^resize_inode -O meta_bg",
	"-O huge_file -O dir_nlink -O uninit_bg -O ^resize_inode -O meta_bg \
-O flex_bg",
	"-O huge_file -O dir_nlink -O metadata_csum",
	"-O huge_file -O dir_nlink -O metadata_csum -O ^resize_inode -O meta_bg",
	"-O huge_file -O dir_nlink -O metadata_csum -O ^resize_inode -O flex_bg",
	"-O huge_file -O dir_nlink -O metadata_csum -O ^resize_inode -O meta_bg \
-O flex_bg",
	"-O huge_file -O dir_nlink -O uninit_bg -O extents",
	"-O huge_file -O dir_nlink -O uninit_bg -O extents -O ^resize_inode \
-O meta_bg",
	"-O huge_file -O dir_nlink -O uninit_bg -O extents -O ^resize_inode \
-O flex_bg",
	"-O huge_file -O dir_nlink -O uninit_bg -O extents -O ^resize_inode \
-O flex_bg -O meta_bg",
	"-O huge_file -O dir_nlink -O uninit_bg -O extents -O metadata_csum",
	"-O huge_file -O dir_nlink -O extents -O 64bit",
	"-O huge_file -O dir_nlink -O extents -O 64bit -O metadata_csum",
	"-O huge_file -O dir_nlink -O extents -O 64bit -O metadata_csum \
-O ^resize_inode -O flex_bg",
	"-O huge_file -O dir_nlink -O extents -O 64bit -O metadata_csum \
-O ^resize_inode -O meta_bg",
	"-O huge_file -O dir_nlink -O extents -O 64bit -O metadata_csum \
-O ^resize_inode -O flex_bg -O meta_bg"
]

testcases_all = [ "test_mount_unmount.sh", "test_fs_fast.sh" ]
testcases_all_versions = [
	"test_fsx_xattrs.sh", "test_fill_fs.sh", "test_fs_normal.sh"
]
testcases_all_versions_4k = [
	"test_1M_files.sh", "test_fdtree.sh", "test_fs_large.sh"
]
testcases_version_ext4_4k = [ "test_pjdfstest.sh", "test_fill_dirs.sh" ]
testcases_version_ext4_4k_large_dev = ["test_mount_unmount_large.sh" ]

testcases_special = [ ]

def run_testcases(tgt, tgtcfg, testcase, fs_features, block_sizes, dev_size):
	for bs in block_sizes:
		for features in fs_features:
			format_options="-b {} {}".format(bs, features)
			cmd = "cd {}; /bin/sh -e {} \"{}\" \"{}\" \"{}\" \"{}\" || \
			    exit 1".format(tgtcfg.testcases_path, testcase, tgtcfg.dev,
			    dev_size, tgtcfg.mp, format_options)
			ret = tgt.exec_command(cmd)
			if ret != 0:
				print("Test failed")
				exit(1)

def setup(tgt, tgtcfg):
	print("=== CLEANUP AND SETUP")
	tgt.exec_command("rm -r -f {}".format(tgtcfg.testcases_path))
	tgt.exec_command("umount -f {}".format(TargetConfig.dev))
	tgt.exec_command("mdconfig -d -u 0")
	tgt.scp_put_dir(os.path.join(target_path, 'ext2fs_test_all'),
	    tgtcfg.testcases_path)
	tgt.exec_command("chmod +x {}/*".format(tgtcfg.testcases_path))

# MAIN
print("==== {} starting, TARGET = {}".format(job_name, tgt.config.domain))
tgt.exec_command("uname -a")

setup(tgt, TargetConfig)

print("==== run_testcases_all:")
for case in testcases_all:
	print("case = {}".format(case))
	run_testcases(tgt, tgtcfg, case, all_fs_features, tgtcfg.fs_blk_sizes,
	    tgtcfg.dev_size)

print("==== run_testcases_all_versions:")
for case in testcases_all_versions:
	print("case = {}".format(case))
	run_testcases(tgt, tgtcfg, case, fs_ext_ver_features, tgtcfg.fs_blk_sizes,
	    tgtcfg.dev_size)

print("==== run_testcases_all_versions_4k:")
for case in testcases_all_versions_4k:
	print("case = {}".format(case))
	run_testcases(tgt, tgtcfg, case, fs_ext_ver_features, [ "4096" ],
	    tgtcfg.dev_size)

print("==== run_testcases_version_ext4_4k:")
for case in testcases_version_ext4_4k:
	print("case = {}".format(case))
	run_testcases(tgt, tgtcfg, case, ext4_fs_features, [ "4096" ],
	    tgtcfg.dev_size)

print("==== run_testcases_version_ext4_4k_large_dev:")
for case in testcases_version_ext4_4k_large_dev:
	print("case = {}".format(case))
	run_testcases(tgt, tgtcfg, case, ext4_fs_features, [ "4096" ],
	    tgtcfg.dev_large_size)

print("==== run_testcases_special:")
for case in testcases_special:
	print("case = {}".format(case))
	run_testcases(tgt, tgtcfg, case, ext4_fs_features, [ "4096" ],
	    tgtcfg.dev_size)

print('Test done')
tgt.ssh_disconnect()
tgt.vm_stop()
tgt.vm_disconnect()
