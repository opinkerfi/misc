#!/bin/bash

if [ "$USER" != "tito" ]; then
	echo Please run this script as the user tito
	exit 1
fi



main() {
	tito_repos=$(get_all_tito_repos);
	
	for i in $tito_repos; do
		echo "checking $i... "
		git_pull $i && continue # return 0 means no updates
		RESULT=$?
		logfile="/tmp/tito/tito-`basename $i`"
		if [ $RESULT -eq 2 ]; then
			echo "tito release to prod repo: $i (logfile $logfile)"
			release_all_packages $i	--all > $logfile
		fi
		
		if [ $RESULT -eq 1 ]; then
			echo "tito release to test repo: $i (logfile $logfile)"
			release_all_packages $i --all-starting-with=test > $logfile
		fi
		
	done
}

# 
# Prints  to screen all directory's in tito home directory
# That happen to be a git repo
get_all_tito_repos() {
	for i in ~/* ; do
		test -d $i/rel-eng/packages || continue
		echo $i
	done
}

# Run a git pull in given directory
# Returns:
# 0 - If nothing new is in the remote remote
# 1 - If there are updates
# 2 - If there are updates and there is a new tag
# 4 - If there was a problem running git pull
git_pull() {
	cd $1
	OUTPUT=$(git pull 2>/dev/null)
	RESULT=$?
	cd - > /dev/null

	# Check if git pull ran
	if [ $RESULT -ne 0 ]; then
		echo "Problem running git pull in $1"
		return 4
	fi
	# Check if tehre were any updates
	echo $OUTPUT | grep -q 'Already up-to-date'  > /dev/null
	if [ $? -eq 0 ]; then
		return 0
	fi

	# check if there is a new tag
	echo $OUTPUT | grep -q 'new tag' > /dev/null
	if [ $? -eq 0 ]; then
		return 2
	fi
	return 1 
}

#
# Release all packages in a given git repository
#
release_all_packages() {
	cd $1 ; shift
	test -d ./rel-eng/packages || return
	for i in ./rel-eng/packages/* ; do 
		DIRNAME=`cat $i | awk '{ print $2 }'`
		cd ./$DIRNAME
		tito release $@
		cd - > /dev/null
	done
	cd - > /dev/null 
}

main;
