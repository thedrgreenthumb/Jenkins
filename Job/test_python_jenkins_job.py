import os
import sys
import time
import pytest
import tempfile

job_name = os.environ['JOB_NAME']

jenkins_path = os.path.join(os.path.realpath(os.path.dirname(__file__)), '..')
config_path = os.path.join(jenkins_path, 'Config', job_name)
misc_path = os.path.join(jenkins_path, 'Misc')

sys.path.append(config_path)
sys.path.append(misc_path)

from config import ConfigParams
from target import Target
from target import TargetException
from target import target_git_clone

# Testing scenario:

# "vm start, vm stop, vm connection, vm reboot":
# - connect vm, check invalid domain name
# - start vm, check vm already started
# - connect ssh, check cannot connect to ssh: invalid ip, no sshserver, no user
# - execute simple command
# - desconnect, stop vm
# - start vm
# - execute simple command
# - reboot vm
# - execute simple command
# - stop vm

# "ssh command execution"
# - execute valid command, check stdout, stderr
# - execute failed command, check stdout, stderr
# - execute long command, check that control will not be returned until command finished
# - execute long command, check that execution finished after timeout expiration

# "scp from/to target"
# - scp (to target) copy file, directory, check errors (invalid src/dst pathes)
# - scp (from target) copy file, directory, check errors (invalid src/dst pathes)

# "command execution and return values, timeouts"
# - copy valid and invalid scripts to target, execute both, check errors

# "git logic checking"
# clone the repo to the target, check repo exist, repo not available

# "target information collection"
# just check *_dump() functions output

class ConfigBadDomain:
    domain="BadDomain"
    ip="192.168.122.31"
    user="user"
    password="pass"

class ConfigBadIP:
    domain="freebsd12.0"
    ip="192.168.255.31"
    user="user"
    password="pass"

# Assumed test VM turned off
class TestVMStartStop:
    @classmethod
    def setup_class(cls):
        cls.tgt = Target(ConfigParams())
        cls.bad_domain_tgt = Target(ConfigBadDomain())
        cls.bad_ip_tgt = Target(ConfigBadIP())

    def test_vm_reboot_sequence(self):
        try:
            self.tgt.vm_connect()
            assert(self.tgt.vm_active() == False)
            self.tgt.vm_start()
            self.tgt.ssh_connect()
            self.tgt.vm_reboot()
            self.tgt.vm_stop()
            self.tgt.ssh_disconnect()
            self.tgt.vm_disconnect()
        except:
            pytest.fail("Cannot reboot sequence vm domain")

    def test_vm_start_stop_sequence(self):
        try:
            self.tgt.vm_connect()
            assert(self.tgt.vm_active() == False)
            self.tgt.vm_start()
            self.tgt.vm_reboot()
            self.tgt.vm_stop()
            self.tgt.vm_start()
            self.tgt.vm_stop()
            self.tgt.vm_disconnect()
        except:
            pytest.fail("Cannot start/stop sequence vm domain")

    def test_vm_bad_domain(self):
        with pytest.raises(TargetException):
            self.bad_domain_tgt.vm_connect()

    def test_vm_bad_ip(self):
        with pytest.raises(TargetException):
            self.bad_ip_tgt.vm_connect()
            self.bad_ip_tgt.ssh_connect()

# Assumed test VM turned off
class TestVMSSH:
    @classmethod
    def setup_class(cls):
        cls.tgt = Target(ConfigParams())
        cls.tgt.vm_connect()
        assert(cls.tgt.vm_active() == False)
        cls.tgt.vm_start()
        cls.tgt.ssh_connect()

    @classmethod
    def teardown_class(cls):
        # cls.tgt.vm_stop()
        cls.tgt.ssh_disconnect()
        cls.tgt.vm_disconnect()

    def test_ssh_command(self):
        (stdin, stdout, stderr) = self.tgt.exec_command_async('hostname')
        assert(stdout.readlines() == ['fb\n'])
        assert(stderr.readlines() == [])

        (stdin, stdout, stderr) = self.tgt.exec_command_async('unknowncmd')
        assert(stdout.readlines() == [])
        assert(stderr.readlines() == ['sh: unknowncmd: not found\n'])

    def test_ssh_script(self):
        self.tgt.exec_command("echo '#!/bin/sh\nexit 0' > /home/user/test.sh")
        self.tgt.exec_command("chmod 777 /home/user/test.sh")
        ret = self.tgt.exec_script('/home/user/test.sh')
        assert (ret == 0)

        ret = self.tgt.exec_script('notexist.sh')
        assert (ret == 127)

    def test_ssh_script_timeout(self):
        with pytest.raises(TargetException):
            self.tgt.exec_command("echo '#!/bin/sh\nsleep 60' > /home/user/test.sh")
            self.tgt.exec_command("chmod 777 /home/user/test.sh")
            self.tgt.exec_script('/home/user/test.sh', sh_timeout=15)

# Assumed test VM turned on
class TestVMSCP:
    @classmethod
    def setup_class(cls):
        cls.tgt = Target(ConfigParams())
        cls.tgt.vm_connect()
        # assert(cls.tgt.vm_active() == False)
        # cls.tgt.vm_start()
        cls.tgt.ssh_connect()

    @classmethod
    def teardown_class(cls):
        # cls.tgt.vm_stop()
        cls.tgt.ssh_disconnect()
        cls.tgt.vm_disconnect()

    def test_scp_file_put_get(self):
        fo = tempfile.NamedTemporaryFile()
        fo.write(b'FileForSCPTest')
        self.tgt.scp_put(fo.name, '/tmp/test.scp')
        self.tgt.scp_get('/tmp/test.scp', '/tmp/test.scp')
        assert(os.path.isfile('/tmp/test.scp') == True)
        fo.close()

    def test_scp_dir_put(self):
        host_path = '/home/user/Sources/PJenkins'
        target_path = '/home/user/PJenkins'
        self.tgt.scp_put_dir(host_path, target_path, ignore_existing=True)

    # XXX test misc checks here
    def test_bad_cases(self):
        pass

# Assumed test VM turned on
class TestGitCloning:
    def setup_class(cls):
        cls.tgt = Target(ConfigParams())
        cls.tgt.vm_connect()
        # assert(cls.tgt.vm_active() == False)
        # cls.tgt.vm_start()
        cls.tgt.ssh_connect()

    @classmethod
    def teardown_class(cls):
        # cls.tgt.vm_stop()
        cls.tgt.ssh_disconnect()
        cls.tgt.vm_disconnect()

    def test_git_clone(self):
        target_git_clone(self.tgt, '/home/user/', 'https://github.com/thedrgreenthumb/Jenkins.git')

    def test_git_clone_bad_repo_url(self):
        pass

    def test_git_clone_path_not_exist(self):
        pass

    def test_git_clone_bad_target(self):
        pass

# Assumed test VM turned on, turn off it after test completion
class TestDomainStats:
    def setup_class(cls):
        cls.tgt = Target(ConfigParams())
        cls.tgt.vm_connect()
        # assert(cls.tgt.vm_active() == False)
        # cls.tgt.vm_start()
        cls.tgt.ssh_connect()

    @classmethod
    def teardown_class(cls):
        cls.tgt.vm_stop()
        cls.tgt.ssh_disconnect()
        cls.tgt.vm_disconnect()

    def test_dump_stats(self):
        self.tgt.dump_stats()
