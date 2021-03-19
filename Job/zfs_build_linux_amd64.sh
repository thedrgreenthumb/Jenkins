#!/bin/bash

. ${JENKINS_START_HOME}/Config/${JOB_NAME}/config.sh
. ${JENKINS_START_HOME}/Misc/misc.sh
. ${JENKINS_START_HOME}/Misc/misc_git.sh

target_check $TARGET_HOSTNAME
ret=$?
if [ "$ret" != "0" ]; then
	fatal "Incorrect target hostname"
fi

target_info

if [ "$SKIP_SOURCE_UPDATE" != "true" ]; then
	echo "Get git repo"
	if [ -z "$REPO_URL" ]; then
		REPO_URL=$OPENZFS_DEFAULT_URL
	else
		REPO_URL=$(echo "$REPO_URL" | sed -e 's/^"//' -e 's/"$//')
	fi

	echo "Get git branch and commit id"
	if [ -z "$REPO_BRANCH" ]; then
		REPO_BRANCH=$OPENZFS_DEFAULT_BRANCH
	else
		REPO_BRANCH=$(echo "$REPO_BRANCH" | sed -e 's/^"//' -e 's/"$//')
	fi

	COMMIT_ID=$OPENZFS_DEFAULT_COMMIT_ID

	retfile=$(mktemp /tmp/jenkins.XXXXXX)
	target_execute "[ -d $OPENZFS_TARGET_PATH/.git ] && echo exist" 60 "$retfile"
	ret=$(cat $retfile | grep "No such file or directory")
	if [ "$(cat $retfile)" == "exist" ]; then
		echo "Checkout git repo..."
		target_execute "cd $OPENZFS_TARGET_PATH && make clean" $((30*60))
		target_git_checkout "$REPO_URL" "$REPO_BRANCH" "$OPENZFS_TARGET_PATH"
	else
		echo "Clone git repo..."
		target_execute "mkdir $(dirname $OPENZFS_TARGET_PATH)"
		target_execute "rm -r $OPENZFS_TARGET_PATH" $((30*60))
		tagret_git_clone_send "$REPO_URL" "$REPO_BRANCH" "/tmp" "$(dirname $OPENZFS_TARGET_PATH)" "$COMMIT_ID"
	fi
else
	echo "Use local copy of $OPENZFS_TARGET_PATH"
fi

echo "Autotools..."
target_execute "cd $OPENZFS_TARGET_PATH && ./autogen.sh" $((2*60))
if [ "$?" != "0" ]; then
	fatal "Cannot autotools"
fi

echo "Configure..."
target_execute "cd $OPENZFS_TARGET_PATH && ./configure" $((5*60))
if [ "$?" != "0" ]; then
	fatal "Cannot configure"
fi

echo "Build..."
target_execute "cd $OPENZFS_TARGET_PATH && make -j${NUM_CORES}" $((10*60))
if [ "$?" != "0" ]; then
	fatal "Cannot build"
fi

echo "Install..."
target_execute "cd $OPENZFS_TARGET_PATH && echo $SSH_USER_PASS | sudo -S make install" $((10*60))
if [ "$?" != "0" ]; then
	fatal "Cannot install"
fi

echo "Reload moduloes..."
target_execute "echo $SSH_USER_PASS | sudo -S /home/user/Scripts/zfs_reload_modules.sh"
retfile=$(mktemp /tmp/jenkins.XXXXXX)
target_execute "dmesg | grep ZFS" 60 "$retfile"
echo "Got ZFS:"
cat "$retfile"

# TODO:
# add module reloading script to target files

#target_reboot

echo "Build done."
target_info
