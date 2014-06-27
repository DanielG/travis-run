# Copyright (C) 2014  Daniel Gröber <dxld ÄT darkboxed DOT org>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

# This script will be sourced by travis-run

if [ ! -e .travis.yml ]; then
    echo "Error: .travis.yml does not exist.">&2
    exit 1
fi

if [ ! "$OPT_KEEP" ]; then
    trap 'backend_end '"$OPT_VM_NAME" 0 2 15
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
	| backend_run_script "$OPT_VM_NAME" --build \
	| backend_run "$OPT_VM_NAME" copy -- bash

    if [ $? -ne 0 ]; then
    	echo "Build failed, please investigate." >&2
	backend_run "$OPT_VM_NAME" nocopy
    fi
}

cfgs=$(backend_run_script "$OPT_VM_NAME" < .travis.yml)

BIFS="$IFS"
IFS=$(printf '\n'); for cfg in $(printf '%s\n' "$cfgs"); do
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
