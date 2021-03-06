#!/bin/bash
# @Function
# svn merge commit between verison when source branch copy(--stop-on-copy)
# and head version of source branch.
#
# @Usage
#   $ ./svnmerge.sh <source branch> [target branch]
#   if no target branch, merge to current svn direcotry
#
# @author Jerry Lee

usage() {
    cat <<EOF
Usage: ${PROG} <source branch> [target branch]
svn merge commit between verison when source branch copy(--stop-on-copy)
and head version of source branch.

Example: 
	${PROG} http://www.foo.com/project1/branches/feature1
	# merge http://www.foo.com/project1/branches/feature1 to current svn direcotry

	${PROG} http://www.foo.com/project1/branches/feature1 /path/to/svn/direcotry
	# merge branch http://www.foo.com/project1/branches/feature1 to svn direcotry /path/to/svn/direcotry

	${PROG} http://www.foo.com/project1/branches/feature1 http://www.foo.com/project1/branches/feature2
	# merge http://www.foo.com/project1/branches/feature1 to branch http://www.foo.com/project1/branches/feature2
	# because http://www.foo.com/project1/branches/feature2 is remote url, will check out target branch to tmp direcotry,
	# and prompt comfirm for committing to target branch.
EOF
    exit $1
}

[ $# -gt 2 ] && {
	echo "too many arguments!"
	usage 1
}

source_branch=$1
target=${2:-.}

[ -z "$source_branch" ] && {
	echo "missing source branch argument!"
	usage 1
}

[ ! -d "$target" ] && {
	workDir=$(mktemp -d) && svn co "$target" "$workDir" || {
		echo "Fail to checkout target remote branch $target !"
		exit 1
	}
} || workDir="$target"

cleanup() {
	[ "$workDir" = "$target" ] && {
		echo "rm tmp dir $workDir ."
		rm -rf "$workDir"
	}
}
trap "cleanup" EXIT

svnstatusline=$(svn status "$workDir" | wc -l)
[ "$svnstatusline" -ne 0 ] && {
	echo "svn work direcotry is modified!"
	exit 1
}

cd "$workDir" &&
version=$(svn log --stop-on-copy --quiet "$source_branch" | awk '$1~/^r[0-9]+/{print $1}' | tail -n1) && {
	echo "oldest version($version) of source branch $source_branch ."
	echo "starting merge to $workDir ."
	svn merge -$version:HEAD $source_branch
} || {
	echo "Fail to merge to work dir $workDir ."
	exit 2
}

read -p "Check In? (Y/N)" ci
[ "$ci" = "Y" ] && svn ci -m "merge from $source_branch"
