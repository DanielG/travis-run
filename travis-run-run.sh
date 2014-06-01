#!/bin/sh
# This script will be sourced by travis-run

if [ ! -e .travis.yml ]; then
    echo "Error: .travis.yml does not exist.">&2
    exit 1
fi

if [ ! $OPT_KEEP ]; then
    trap "backend_end $OPT_VM_NAME" 0 2 15
fi

backend_init "$OPT_VM_NAME"

if [ $? -ne 0 ]; then
    echo "Starting VM failed">&2
    exit 1
fi

run_tests () {
	# echo 'travis_run_onexit () {'
	# echo 'RV=$?'
	# echo 'if [ $RV -ne 0 ]; then
        #    env | awk -v FS="=" '"'"'{ print "export " $1 "=\"" $2 "\"" }'"'"' >> ~/.bashrc;
        #    exit $RV
        # fi'
	# echo '}'
	# echo 'trap "travis_run_onexit" 0 2 15'

    printf "%s\n" "$1" \
	| backend_run_script $OPT_VM_NAME --build \
	| backend_run $OPT_VM_NAME copy -- bash

    if [ $? -ne 0 ]; then
    	echo "Build failed, please investigate." >&2
	backend_run $OPT_VM_NAME nocopy
    fi
}

cfgs=$(backend_run_script $OPT_VM_NAME < .travis.yml)

BIFS="$IFS"
IFS=$(echo); for cfg in $(printf "%s\n" "$cfgs"); do
    IFS=$BIFS run_tests "$cfg"
    exit
done


#  | while read cfg; do
#
#     echo
#     echo

# #
#     exit
# done

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
