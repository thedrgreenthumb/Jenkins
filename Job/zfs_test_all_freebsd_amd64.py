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
tgt.vm_start()
tgt.ssh_connect()

class TargetConfig:
	testcases_path="/home/user/zfs_test_all"

tgtcfg = TargetConfig()

def setup(tgt, tgtcfg):
	print("==== CLEANUP AND SETUP ====")
	print("====== {} starting, TARGET={}".format(job_name, tgt.config.ip))
	tgt.exec_command("dmesg | grep ZFS")
	tgt.exec_command("rm -r -f {}".format(tgtcfg.testcases_path))
	tgt.scp_put_dir(os.path.join(target_path, 'zfs_test_all'),
	    tgtcfg.testcases_path)
	tgt.exec_command("chmod +x {}/*".format(tgtcfg.testcases_path))

# MAIN
setup(tgt, TargetConfig)

cmd = "cd {}; /bin/sh -e {} {}".format(tgtcfg.testcases_path, 'test_all.sh',
    os.path.join(tgt.config.source_dir, 'zfs'))
ret = tgt.exec_command(cmd)
if ret != 0:
	print("Testing... FAILED")
	exit(1)

print('Test done')
tgt.ssh_disconnect()
tgt.vm_stop()
tgt.vm_disconnect()
