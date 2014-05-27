#!/bin/sh
# This script will be sourced by travis-run

if [ ! -e .travis.yml ]; then
    echo "Error: .travis.yml does not exist.">&2
    exit 1
fi

if [ ! $OPT_KEEP ]; then
    trap "backend_end $OPT_VM_NAME" 2 15
fi

backend_init "$OPT_VM_NAME"

if [ $? -ne 0 ]; then
    echo "Starting VM failed">&2
    exit 1
fi

RUN="backend_run $OPT_VM_NAME copy $@"
RUN_nocopy="backend_run $OPT_VM_NAME nocopy $@"

run_tests () {
    (
	# echo 'travis_run_onexit () {'
	# echo 'RV=$?'
	# echo 'if [ $RV -ne 0 ]; then
        #    env | awk -v FS="=" '"'"'{ print "export " $1 "=\"" $2 "\"" }'"'"' >> ~/.bashrc;
        #    exit $RV
        # fi'
	# echo '}'
	# echo 'trap "travis_run_onexit" 0 2 15'

	echo "cd build"
	printf "%s\n" "$1" | $(dirname $0)/travis-run-script --build
    ) | $RUN -- bash # travis-build seems to assume bash :/

    if [ $? -ne 0 ]; then
    	echo "Build failed, please investigate." >&2
    	if [ x"$OPT_BACKEND" = x"vagrant" ]; then
    	    $RUN_nocopy
    	else
    	    $RUN_nocopy -- bash

	    if [ ! $OPT_KEEP ]; then
		backend_end $OPT_VM_NAME
	    fi

    	    exit
    	fi
    fi
}

cfgs=$($(dirname $0)/travis-run-script)
BIFS=$IFS; IFS="\n"
for cfg in "$cfgs"; do
    IFS=$BIFS run_tests "$cfg"
done
IFS=$BIFS

# # TODO: get --exclude's from .gitignore
# rsync -e "$(which ssh) $SSH_OPTS" -lEr --chmod=775 \
#     --rsync-path="sudo -u travis rsync" \
#     --exclude='/.cabal-sandbox/*' \
#     --exclude='/cabal.sandbox.config' \
#     --exclude='dist/*' \
#     --exclude='.git/*' \
#     --delete \
#     --delete-excluded \
#     ./ "$server:/home/travis/$(strip_home $PWD)"


if [ ! $OPT_KEEP ]; then
    backend_end $OPT_VM_NAME
fi
