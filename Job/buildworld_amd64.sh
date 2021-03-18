#!/bin/bash

. ${JENKINS_START_HOME}/Config/${JOB_NAME}/config.sh
. ${JENKINS_START_HOME}/Misc/misc.sh
. ${JENKINS_START_HOME}/Misc/misc_git.sh

# Build vars
LOCAL_BRANCH=""
LOCAL_COMMIT_ID=""

target_check $TARGET_HOSTNAME
ret=$?
if [ "$ret" != "0" ]; then
	fatal "Incorrect target hostname"
fi

target_info

if [ "$SKIP_CLONE" != "true" ]; then
	echo "Get git repo"
	if [ -z "$REPO_URL" ]; then
		REPO_URL=$FREEBSD_DEFAULT_URL
	else
		REPO_URL=$(echo "$REPO_URL" | sed -e 's/^"//' -e 's/"$//')
	fi

	echo "Get git branch and commit id"
	if [ -z "$REPO_BRANCH" ]; then
		REPO_BRANCH=$FREEBSD_DEFAULT_BRANCH
	else
		REPO_BRANCH=$(echo "$REPO_BRANCH" | sed -e 's/^"//' -e 's/"$//')
	fi

	retfile=$(mktemp /tmp/jenkins.XXXXXX)
	target_execute "ls -lah /usr/src/.git" 60 $retfile
	if "$(cat $retfile)" | grep -q "No such file or directory"; then
		target_execute "rm -r -f /usr/src" $((60*60)) $retfile
		target_git_clone "$REPO_URL" "$REPO_BRANCH" "/usr/src"
	else
		target_git_checkout "$REPO_URL" "$REPO_BRANCH" "/usr/src"
	fi
else
	echo "Use local copy of /usr/src"
fi

target_execute "rm -r -f /usr/obj" $((30*60))

echo "Get local branch and commit ID..."
retfile=$(mktemp /tmp/jenkins.XXXXXX)
target_execute "cd /usr/src && git branch --show-current" 60 "$retfile"
LOCAL_BRANCH=$(cat "$retfile")

if [ -z "$COMMIT_ID" ]; then
	target_execute "cd /usr/src && git rev-parse HEAD" 60 "$retfile"
	LOCAL_COMMIT_ID=$(cat "$retfile")
else
	LOCAL_COMMIT_ID=$COMMIT_ID
fi

echo "Buildworld..."
target_execute "cd /usr/src && make -j${NUM_CORES} buildworld" $((6*60*60))
if [ "$?" != "0" ]; then
	fatal "Cannot buildworld"
fi

echo "Buildkernel..."
target_execute "cd /usr/src && make -j${NUM_CORES} kernel" $((60*60))
if [ "$?" != "0" ]; then
	fatal "Cannot build kernel"
fi

target_reboot

echo "Installworld..."
target_execute "cd /usr/src && make installworld" $((30*60))
if [ "$?" != "0" ]; then
	fatal "Cannot install world"
fi

target_reboot

echo "Validate running kernel..."
target_execute "uname -a | awk -F ' ' '{print $6}' | awk -F '-' '{print $3}'" \
    60 "$retfile"
if echo "$LOCAL_COMMIT_ID" | grep -q "$(cat $retfile)"; then
	echo "Kernel is valid: branch=$LOCAL_BRANCH, commitID=$LOCAL_COMMIT_ID"
else
	fatal "Got invalid kernel commit ID in the end of build step"
fi

echo "Build done."
target_info
