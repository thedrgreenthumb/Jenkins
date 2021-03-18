#!/bin/sh

#
# args:
# $1 - git url
#
repo_name()
{
	bname=$(basename $url)
	echo "${bname%.*}"
}

#
# args:
# $1 - repo url
# $2 - repo branch
# $3 - target local path
#
target_git_clone()
{
	url=$1
	branch=$2
	path=$3

	target_execute "ls -lah $(dirname $path))"
	if [ "$?" != "0" ]; then
		fatal "Path for repo cloning does not exist"
	fi

	echo "Remove $path directory"
	target_execute "rm -r -f $path" $((30*60))

	target_execute "git clone --progress --branch $branch $url $path" $((60*60))
	if [ "$?" != "0" ]; then
		fatal "Cannot checkout sources"
	fi
}

#
# args:
# $1 - repo url
# $2 - repo branch
# $3 - target local path
#
target_git_checkout()
{
	url=$1
	branch=$2
	path=$3

	target_execute "ls -lah $(dirname $path))"
	if [ "$?" != "0" ]; then
		fatal "Path for repo cloning does not exist"
	fi

	target_execute "cd $path && git pull" $((120*60))
	if [ "$?" != "0" ]; then
		fatal "Cannot pull sources"
	fi

	target_execute "cd $path && git checkout $branch" $((120*60))
	if [ "$?" != "0" ]; then
		fatal "Cannot checkout sources"
	fi
}

#
# args:
# $1 - repo url
# $2 - repo branch
# $3 - runner local path
# $4 - target local path
# $5 - commit id
#
tagret_git_clone_send()
{
	url=$1
	branch=$2
	runner_path=$3
	target_path=$4
	commit_id=$5
	repo=$(repo_name $url)

	rm -r -f "${runner_path}/${repo}"
	rm -r -f "${runner_path}/${repo}.zip"

	git clone --progress --branch "$branch" "$url" "$runner_path/$repo"
	if [ "$?" != "0" ]; then
		fatal "Cannot clone sources"
	fi

	if [ ! -z $commit_id ]; then
		log "Checkout specified commit: $commit_id"
		cd "$runner_path/$repo" && git reset --hard "$commit_id"
	fi

	cd $runner_path && zip -r ${repo}.zip $repo
	if [ "$?" != "0" ]; then
		fatal "Cannot zip sources"
	fi

	target_scp_to $runner_path/${repo}.zip $target_path
	if [ "$?" != "0" ]; then
		fatal "Cannot scp sources"
	fi

	target_execute "cd  $target_path && unzip ${repo}.zip" $((60*60))
	if [ "$?" != "0" ]; then
		fatal "Cannot unzip sources"
	fi

	target_execute "rm $target_path/${repo}.zip"
}
