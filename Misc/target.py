import os
import select
import subprocess
import logging
import libvirt
import paramiko
import time
import tempfile
import shutil
import logging
import git
from git import Repo
from xml.etree import ElementTree

logging.basicConfig(level=logging.INFO, format='%(levelname)-8s %(message)s')

class TargetException(Exception):
    pass

class Target:
    ping_timeout = 180
    connect_timeout = 120
    default_sh_timeout = 120
    vm_stop_timeout = 240

    ssh_connected = False

    def __init__(self, config):
        self.config = config
    
    def vm_wait_ping(self):
        count = self.ping_timeout
        while count > 0:
            r = os.system("ping -c 1 " + self.config.ip + ' >/dev/null 2>&1')
            if r == 0:
                break;
            count -= 1
            time.sleep(1)
        else:
            msg = 'Host ' + self.config.ip + ' unreachable'
            logging.error(msg)
            raise TargetException(msg)

    def vm_lookup(self):
        try:
            return self.conn.lookupByName(self.config.domain)
        except libvirt.libvirtError as e:
            msg = 'Cannot lookup domain: ' + self.config.domain
            logging.error(msg)
            raise TargetException(msg)

    # Start VM
    def vm_start(self):
        dom = self.vm_lookup()

        # VM is turned off
        if self.vm_active() == True:
            msg = 'Domain ' + self.config.domain + ' already started'
            logging.error(msg)
            raise TargetException(msg)

        if dom.create() < 0:
            msg = 'Can not boot guest domain ' + self.config.domain
            logging.error(msg)
            raise TargetException(msg)

        # Wait VM will be pinged
        time.sleep(10)
        self.vm_wait_ping()

        # Wait to start ssh server
        time.sleep(10)

    # Check VM started
    def vm_active(self):
        return self.vm_lookup().isActive()

    # Stop VM
    def vm_stop(self):
        if self.vm_active() == False:
            msg = 'Domain ' + self.config.domain + ' already stopped'
            logging.error(msg)
            raise TargetException(msg)

        if self.vm_lookup().shutdown() < 0:
            msg = 'Can not stop guest domain ' + self.config.domain
            logging.error(msg)
            raise TargetException(msg)

        # Waiting VM stopping
        count = self.vm_stop_timeout
        while count >= 0:
            if self.vm_active() == False:
                break

            count-=1;
            time.sleep(1)
        else:
            msg = 'Domain cannot be stopped ' + self.config.domain
            logging.error(msg)
            raise TargetException(msg)

    # Reboot VM
    def vm_reboot(self):
        do_ssh_connect = False

        if self.vm_active() == False:
            msg = 'Domain ' + self.config.domain + ' already stopped'
            logging.error(msg)
            raise TargetException(msg)

        if self.ssh_connected == True:
            do_ssh_connect = True
            self.ssh_disconnect()

        if self.vm_lookup().reboot() < 0:
            msg = 'Can not reboot guest domain ' + self.config.domain
            logging.error(msg)
            raise TargetException(msg)

        # Wait VM will be pinged
        time.sleep(120) # wait shutdown phase of reboot
        self.vm_wait_ping()

        # Reconnect ssh
        if do_ssh_connect == True:
            time.sleep(120) # wait ssh server started
            self.ssh_connect()

    def ssh_connect(self):
        try:
            self.ssh = paramiko.SSHClient()
            self.ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
            if self.config.private_key == None:
                self.ssh.connect(self.config.ip, username=self.config.user,
                    password=self.config.password)
            else:
                key_file = os.path.expanduser(self.config.private_key)
                key = paramiko.Ed25519Key.from_private_key_file(key_file, password=self.config.private_key_pass)
                self.ssh.connect(self.config.ip, username=self.config.user,
                    pkey=key)
        except:
            msg = "Paramiko connect error" # + sys.exc_info()[0]
            logging.error(msg)
            raise TargetException(msg)

        self.ssh_connected = True

    def vm_connect(self):
        try:
            self.conn = libvirt.open("qemu:///system")
        except libvirt.libvirtError as e:
            msg = 'Can not open libvirt '
            logging.error(msg)
            raise TargetException(msg)

        self.vm_lookup()

    def ssh_disconnect(self):
        self.ssh.close()
        self.ssh_connected = False

    def vm_disconnect(self):
        self.conn.close()

    # Exec ssh command (paramico)
    def exec_command(self, command, dump=True):
        logging.info("EXEC ({}) cmd: {},".format(self.config.ip, command))
        try:
            chan = self.ssh.get_transport().open_session()
            chan.exec_command(command)
            while True:
                if chan.exit_status_ready():
                    break

                stdout = chan.makefile("r", -1)
                stderr = chan.makefile_stderr("r", -1)
                for line in iter(stdout.readline, ""):
                    logging.info("({}) : {}".format(self.config.ip, line.rstrip('\n')))
                    if dump == True: print(line, end="")
                for line in iter(stderr.readline, ""):
                    logging.info("({}) : {}".format(self.config.ip, line.rstrip('\n')))
                    if dump == True: print(line, end="")

            return chan.recv_exit_status()
        except:
            msg = "Paramiko exec command error" # + sys.exc_info()[0]
            logging.error(msg)
            raise TargetException(msg)

    def exec_command_async(self, command):
        try:
            return self.ssh.exec_command(command)
        except:
            msg = "Paramiko exec async command error" # + sys.exc_info()[0]
            logging.error(msg)
            raise TargetException(msg)

    # Exec ssh command (paramico)
    def exec_script(self, target_path, args="", sh_timeout=default_sh_timeout):
        try:
            command = 'timeout ' + str(sh_timeout) + 's ' + target_path + ' ' + args
            chan = self.ssh.get_transport().open_session()
            chan.exec_command(command)
            ret = chan.recv_exit_status()
            if ret == 124:
                msg = "Paramiko exec command timeout" # + sys.exc_info()[0]
                logging.error(msg)
                raise TargetException(msg)
            return ret

            # XXX possible it is needed to read streams explicitly
            #while True:
            #    if chan.exit_status_ready():
            #        return chan.recv_exit_status()
            #    rl, wl, xl = select.select([chan], [], [], 0.0)
        except:
            msg = "Paramiko exec command error" # + sys.exc_info()[0]
            logging.error(msg)
            raise TargetException(msg)

    # Copy file to target
    def scp_put(self, host_path, target_path):
        if os.path.exists(os.path.dirname(host_path)) == False:
            msg = "Host path does not exist: " + host_path
            logging.error(msg)
            raise TargetException(msg)

        sftp = self.ssh.open_sftp()
        sftp.put(host_path, target_path)
        sftp.close()

    def __put_dir(self, sftp, source, target):
        ''' Uploads the contents of the source directory to the target path. The
            target directory needs to exists. All subdirectories in source are 
            created under target.
        '''
        for item in os.listdir(source):
            if os.path.isfile(os.path.join(source, item)):
                sftp.put(os.path.join(source, item), '%s/%s' % (target, item))
            else:
                try:
                    # XXX can throw exception if target directory exist, need to check
                    sftp.mkdir('%s/%s' % (target, item))
                except IOError as e:
                    msg = str(e)
                    logging.warning('sftp mkdir error ' + msg)
                self.__put_dir(sftp, os.path.join(source, item), '%s/%s' % (target, item))

    def scp_put_dir(self, host_path, target_path, ignore_existing=False):
        if os.path.exists(host_path) == False:
            msg = "Host path does not exist: " + host_path
            logging.error(msg)
            raise TargetException(msg)

        sftp = self.ssh.open_sftp()
        try:
            mode = 511
            sftp.mkdir(target_path, mode)
        except IOError:
            if ignore_existing:
                pass
            else:
                msg = "Target path already exist: " + target_path
                logging.error(msg)
                raise TargetException(msg)

        self.__put_dir(sftp, host_path, target_path)
        sftp.close()

    # Copy file from target
    def scp_get(self, host_path, target_path):
        if os.path.exists(os.path.dirname(host_path)) == False:
            msg = "Host path does not exist: " + host_path
            logging.error(msg)
            raise TargetException(msg)

        # XXX check host path is directory

        sftp = self.ssh.open_sftp()
        sftp.get(target_path, host_path)
        sftp.close()

    # Target info (hostname, uname -a report)
    def dump_info(self):
        cmd = "hostname ; uname -a"
        return self.ssh.exec_command(cmd, timeout=self.default_ssh_timeout)

    def set_memory(self, mb):
        if self.vm_active() == True:
            msg = 'Domain ' + self.config.domain + ' is started'
            logging.error(msg)
            raise TargetException(msg)

        process = subprocess.Popen(['which', 'virsh'])
        ret = process.wait()
        if ret != 0:
            logging.warning("target: virsh is not installed")

        dom = self.config.domain
        mem_kb=mb*1024
        process = subprocess.Popen(['virsh', 'setmem', dom, str(mem_kb), '--config'])
        ret = process.wait()
        if ret != 0:
            msg = "Cannot set ram ({} kb) for domain {}".format(str(mem_kb), dom)
            logging.error(msg)
            raise TargetException(msg)

    def set_vcpus(self, numvpus):
        if self.vm_active() == True:
            msg = 'Domain ' + self.config.domain + ' is started'
            logging.error(msg)
            raise TargetException(msg)

        process = subprocess.Popen(['which', 'virsh'])
        ret = process.wait()
        if ret != 0:
            logging.warning("target: virsh is not installed")

        dom = self.config.domain
        process = subprocess.Popen(['virsh', 'setvcpus', dom, numvpus, '--config'])
        ret = process.wait()
        if ret != 0:
            msg = "Cannot set vcpus () for domain {}".format(numvpus, dom)
            logging.error(msg)
            raise TargetException(msg)

    # Target VM stats
    def dump_stats(self):
        # https://libvirt.org/docs/libvirt-appdev-guide-python/en-US/html/libvirt_application_development_guide_using_python-Guest_Domains-Monitoring.html
        print('======== Domain ' + self.config.domain + ' statistics =======')
        print('======== Domain info: =======================================')
        print('ip=' + self.config.ip + ' user=' + self.config.user)

        dom = self.vm_lookup()

        print('======== CPU info: ==========================================')
        stats = dom.getCPUStats(True)
        print('cpu_time:    '+str(stats[0]['cpu_time']))
        print('system_time: '+str(stats[0]['system_time']))
        print('user_time:   '+str(stats[0]['user_time']))

        print('======== RAM info: ==========================================')
        stats = dom.memoryStats()
        print('memory used:')
        for name in stats:
           print('  '+str(stats[name])+' ('+name+')')

        print('======== IO info: ===========================================')
        tree = ElementTree.fromstring(dom.XMLDesc())
        iface = tree.find('devices/interface/target').get('dev')
        stats = dom.interfaceStats(iface)
        print('read bytes:    '+str(stats[0]))
        print('read packets:  '+str(stats[1]))
        print('read errors:   '+str(stats[2]))
        print('read drops:    '+str(stats[3]))
        print('write bytes:   '+str(stats[4]))
        print('write packets: '+str(stats[5]))
        print('write errors:  '+str(stats[6]))
        print('write drops:   '+str(stats[7]))

def target_check_hostname(target, hostname):
    (stdin, stdout, stderr) = target.exec_command_async('hostname')
    if stdout.readlines() == [ "{}\n".format(hostname) ]:
        return 0

    return 1

def target_git_clone(target, target_path, git_url, git_branch='master',
    git_commit=None):
    dirpath = tempfile.mkdtemp()

    logging.info("Clone repo={}, branch={}, commit_id={}, to path={} => START \
        ".format(git_url, git_branch, git_commit, target_path))

    repo = Repo.clone_from(git_url, dirpath, branch=git_branch)
    if git_commit is not None:
        repo.git.checkout(git_commit)

    logging.debug("Repo {} cloned, archiving...".format(git_url))

    remote_url = repo.remotes[0].config_reader.get("url")
    repo_name = os.path.splitext(os.path.basename(remote_url))[0]
    target_archive_path = os.path.join(target_path, repo_name + '.zip')
    target_repo_path = os.path.join(target_path, repo_name)

    shutil.make_archive(dirpath, 'zip', dirpath)

    logging.debug("Repo {} archived, transferring...".format(git_url))

    ret = target.exec_command("[ -d {} ]".format(target_repo_path))
    if ret == 0:
        logging.warning("path {}, already exist".format(target_repo_path))

    target.exec_command("rm -r -f " + target_repo_path)
    target.exec_command("mkdir " + target_repo_path)
    target.scp_put(dirpath + '.zip', target_archive_path)

    logging.debug("Repo {} transferred, unpacking...".format(git_url))

    target.exec_command("mv " + target_archive_path + ' ' + target_repo_path)
    target.exec_command('cd ' + target_repo_path + ' ; ' +
        ' unzip ' + repo_name + '.zip', dump=False)
    target.exec_command('cd ' + target_repo_path + ' ; ' +
        ' rm ' + repo_name + '.zip')

    ret = target.exec_command("which git")
    if ret != 0:
        logging.warning("target: git is not installed")
    else:
        git_revert_typechange ='git status | grep typechange \
            | awk \'{print $2}\' | xargs git checkout'
        target.exec_command('cd ' + target_repo_path + ' ; ' +
            git_revert_typechange)

    logging.info("Clone repo={} => DONE".format(git_url))

def target_git_get_commit_id(target, target_path):
    cmd = 'cd ' + target_path + ' && ' + 'git rev-parse HEAD'
    (stdin, stdout, stderr) = target.exec_command_async(cmd)
    return stdout.readline()
