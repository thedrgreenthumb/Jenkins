#!/bin/sh

TIMEOUT_DEFAULT=60
TARGET_UNAME_OUT=""

log()
{
	echo "LOG: $1"
}

warning()
{
	echo "WARNING: $1"
}

fatal()
{
	echo "FATAL: $1"
	exit 1
}

#
# args:
# none
#
target_info()
{
	retfile=$(mktemp /tmp/$TMP_PREFIX.XXXXXX)
	target_execute "uname -a" 60 "$retfile"
	TARGET_UNAME_OUT=$(cat "$retfile")

	echo "Target info:"
	cat "$retfile"
}

#
# args:
# none
#
target_kernel_is_modified()
{
	retfile=$(mktemp /tmp/$TMP_PREFIX.XXXXXX)
	target_execute "uname -a" 60 "$retfile"

	if [ "$TARGET_UNAME_OUT" != "$(cat $retfile)" ]; then
		return 1
	fi

	return 0
}

#
# args:
# $1 = expected hostname
#
target_check()
{
	tmpfile=$(mktemp /tmp/$TMP_PREFIX.XXXXXX)

	log "check target..."

	target_execute "hostname" 60 $tmpfile

	if [ "$1" != "$(cat $tmpfile)" ]; then
		return 1
	fi

	return 0
}

#
# args:
# $1 = command to execute on ssh
# $2 = timeout
# $3 = output to file
#
target_execute()
{
	TIMEOUT=$2

	if [ -z "$2" ]; then
		TIMEOUT=$TIMEOUT_DEFAULT
	fi

	log "ssh ${SSH_OPTS} ${SSH_USER}@${SSH_IP} \"$1\", \
	    TIMEOUT=$TIMEOUT, OUTFILE=$3"
	
	if [ -z "$3" ]; then
		timeout $TIMEOUT ssh ${SSH_OPTS} ${SSH_USER}@${SSH_IP} "$1"
	else
		timeout $TIMEOUT ssh ${SSH_OPTS} ${SSH_USER}@${SSH_IP} "$1" > "$3"
	fi

	ret=$?
	if [ "$ret" -eq "124" ]; then 
		fatal "Timeout expired..."
	fi

	return $ret
}

#
# args:
# none
#
target_reboot()
{
	if [ "$SSH_USER" == "root" ]; then
		target_execute "reboot"
	else
		target_execute "echo $SSH_USER_PASS | sudo -S reboot"
	fi

	log "reboot target: ${SSH_USER}@${SSH_IP}, waiting..."

	sleep 180

	while true; do
		ssh ${SSH_OPTS} ${SSH_USER}@${SSH_IP} "hostname" >/dev/null 2>&1
		ret=$?
		if [ "$ret" -eq "0" ]; then
			break;
		fi

		sleep 1
	done
}

#
# args:
# $1 = path to file to copy from
# $2 = path to file to copt to
#
target_scp_from()
{
	log "scp ${SSH_OPTS} ${SSH_USER}@${SSH_IP}:$1 $2"

	scp ${SSH_OPTS} ${SSH_USER}@${SSH_IP}:$1 $2
	ret=$?
	if [ "$ret" -ne "0" ]; then
		fatal "Cannot scp form ${SSH_USER}@${SSH_IP}:$1 to $2"
	fi
}

#
# args:
# $1 = path to file to copy from
# $2 = path to file to copt to
#
target_scp_to()
{
	log "scp ${SSH_OPTS} $1 ${SSH_USER}@${SSH_IP}:$2"

	scp -r ${SSH_OPTS} $1 ${SSH_USER}@${SSH_IP}:$2
	ret=$?
	if [ "$ret" -ne "0" ]; then
		fatal "Cannot scp to ${SSH_USER}@${SSH_IP}:$2 from $1"
	fi
}