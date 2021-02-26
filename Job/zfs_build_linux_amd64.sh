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

target_execute "mkdir $(dirname $OPENZFS_TARGET_PATH)"
target_execute "rm -r $OPENZFS_TARGET_PATH" $((30*60))
tagret_git_clone_send "$REPO_URL" "$REPO_BRANCH" "/tmp" "$(dirname $OPENZFS_TARGET_PATH)" "$COMMIT_ID"

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

#echo "Install..."
#target_execute "cd $OPENZFS_TARGET_PATH && echo $SSH_USER_PASS | sudo -S make install" $((10*60))
#if [ "$?" != "0" ]; then
#	fatal "Cannot install"
#fi

#target_reboot

echo "Build done."
target_info
