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

sys.path.append(config_path)
sys.path.append(misc_path)

from config import ConfigParams
from target import Target
from target import TargetException
from target import target_check_hostname
from target import target_git_clone
from target import target_git_get_commit_id

tgt = Target(ConfigParams())

tgt.vm_connect()

required_ram = 32768
required_vcpus = 32
tgt.set_memory(required_ram)
tgt.set_vcpus(required_vcpus)
print("Set ram {} and vcpus {}".format(required_ram, required_vcpus))

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
	tgt.exec_command('rm -r -f /usr/src')
	tgt.exec_command('mv /usr/freebsd-src /usr/src')

print("Buildworld...")
cmd = 'cd ' + os.path.join(tgt.config.source_dir, 'src') + ' ; ' + \
    'make -j' + str(tgt.config.num_cores) + ' buildworld'
ret = tgt.exec_command(cmd)
if ret != 0:
	print("Buildworld... FAILED")
	exit(1)

print("Buildkernel...")
cmd = 'cd ' + os.path.join(tgt.config.source_dir, 'src') + ' ; ' + \
    'make -j' + str(tgt.config.num_cores) + ' kernel'
ret = tgt.exec_command(cmd)
if ret != 0:
	print("Buildworld... FAILED")
	exit(1)

tgt.vm_reboot()

print("Installworld...")
cmd = 'cd ' + os.path.join(tgt.config.source_dir, 'src') + ' ; ' + \
    'make ' + ' installworld'
ret = tgt.exec_command(cmd)
if ret != 0:
	print("Installworld... FAILED")
	exit(1)

tgt.vm_reboot()

# Validate running kernel
(stdin, stdout, stderr) = tgt.exec_command_async('uname -a')
uname = stdout.readline()
commit = target_git_get_commit_id(tgt, os.path.join(tgt.config.source_dir, 'src'))
if uname.find(commit[0:6]) == -1:
	print("Kernel validation... FAILED")
	exit(1)

print('Build done')
tgt.ssh_disconnect()
tgt.vm_stop()
tgt.vm_disconnect()

