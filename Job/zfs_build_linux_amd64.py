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
from target import TargetException
from target import target_check_hostname
from target import target_git_clone

tgt = Target(ConfigParams())

tgt.vm_connect()
tgt.vm_start()
tgt.ssh_connect()

ret = target_check_hostname(tgt, tgt.config.hostname)
if ret != 0:
	print("Bad target hostname... FAILED")
	exit(1)

if skip_source_update == None:	
	if repo_url == None:
		repo_url = tgt.config.default_repo_url

	if repo_branch == None:
		repo_branch = tgt.config.default_repo_branch

	if repo_commit_id == None:
		repo_commit_id = tgt.config.default_repo_commit_id

	src_dir = tgt.config.source_dir
	target_git_clone(tgt, src_dir, repo_url, repo_branch, repo_commit_id)

print('Autotools...')
cmd = 'cd ' + os.path.join(tgt.config.source_dir, 'zfs') + ' ; ' + \
    './autogen.sh'
ret = tgt.exec_command(cmd)
if ret != 0:
	print("Autotools... FAILED")
	exit(1)

print('Configure...')
cmd = 'cd ' + os.path.join(tgt.config.source_dir, 'zfs') + ' ; ' + \
    './configure'
ret = tgt.exec_command(cmd)
if ret != 0:
	print("Configure... FAILED")
	exit(1)

print('Build...')
cmd = 'cd ' + os.path.join(tgt.config.source_dir, 'zfs') + ' ; ' + \
    'make -j' + str(tgt.config.num_cores)
ret = tgt.exec_command(cmd)
if ret != 0:
	print("Build... FAILED")
	exit(1)

print("Install...")
cmd = 'cd ' + os.path.join(tgt.config.source_dir, 'zfs') + ' ; ' + \
	'sudo make install'
ret = tgt.exec_command(cmd)
if ret != 0:
	print("Install... FAILED")
	exit(1)

print("Reload...")
tgt.scp_put(os.path.join(target_path, 'zfs_build', 'zfs_reload_modules.sh'), \
	os.path.join(tgt.config.source_dir, 'zfs_reload_modules.sh'))
cmd = 'cd ' + tgt.config.source_dir + ' ; ' + \
	"chmod 777 ./zfs_reload_modules.sh" + ' ; ' + \
	"ZFS_SOURCE_TARGET={} sudo -E ./zfs_reload_modules.sh".format(
	os.path.join(tgt.config.source_dir, 'zfs'))
ret = tgt.exec_command(cmd)
if ret != 0:
	print("Reload... FAILED")
	exit(1)

cmd = 'dmesg | grep ZFS'
(stdin, stdout, stderr) = tgt.exec_command_async(cmd)
print("ZFS version:")
print(stdout.readlines())

print('Build done')
tgt.ssh_disconnect()
tgt.vm_stop()
tgt.vm_disconnect()
