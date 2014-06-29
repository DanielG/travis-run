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

if [ "$1" ]; then
    BUILD_ID="$1"; shift
else
    unset BUILD_ID
fi

if [ "$1" ]; then
    error "Error: Unexpected arguments: \`$@'"
    exit 1
fi

init () {
    [ "$INITIALIZED" ] && exit

    INITIALIZED=1

    backend_init "$OPT_VM_NAME"

    if [ $? -ne 0 ]; then
	echo "Starting VM failed">&2
	exit 1
    fi

    if [ ! "$OPT_KEEP" ]; then
	# Stop VM in background on SIGINT
	trap 'CANCELLED=1; echo; backend_end '"$OPT_VM_NAME"'' 2

	# exit
	trap '[ $? != 0 ] && [ ! "$CANCELLED" ] && backend_end '"$OPT_VM_NAME" 0

	# SIGTERM
	trap 'backend_end '"$OPT_VM_NAME" 15
    fi
}

run_tests () {
	# echo 'travis_run_onexit () {'
	# echo 'RV=$?'
	# echo 'if [ $RV -ne 0 ]; then
        #    env | awk -v FS="=" '"'"'{ print "export " $1 "=\"" $2 "\"" }'"'"' >> ~/.bashrc;
        #    exit $RV
        # fi'
	# echo '}'
	# echo 'trap "travis_run_onexit" 0 2 15'

    local script
    script=$(printf '%s\n' "$1" \
	| backend_run_script "$OPT_VM_NAME" --build 2>/dev/null)

    if [ $? != 0 ]; then
    	echo "Error: Generating build script failed." >&2
	exit 1
    fi

    printf '%s' "$script" | backend_run "$OPT_VM_NAME" copy -- bash 2>&1  \
	| $STDBUF sed -r 's/(\x1b\[[^m]+.*)/\1\x1b[0m/g' \
	| $STDBUF sed -r 's/\r/\n/g' 1>&2

    if [ $? -ne 0 ] && [ ! $CANCELLED ]; then
    	echo "Build failed, please investigate." >&2
	backend_run "$OPT_VM_NAME" nocopy
	return 1
    fi

    echo "Build Succeeded :)\n\n\n" >&2
}

if [ $OPT_SHELL ]; then
    init
    backend_run "$OPT_VM_NAME" copy -- true
    backend_run "$OPT_VM_NAME" nocopy
    exit
fi
cfgs=$(backend_run_script "$OPT_VM_NAME" < .travis.yml)

id=0
printf '%s\n' "$cfgs" | while IFS=$(printf '\n') read -r line; do
    unset label; unset cfg
    eval $(printf '%s' "$line")
    [ ! "$cfg" ] && continue

    if [ "$BUILD_ID" = "$(echo -n "$BUILD_ID" | tr -dc '[0-9]')" ]; then
	num=1
    else
	num=0
    fi

    if [ ! "$BUILD_ID" ] \
	|| [ x"$BUILD_ID" = x"$label" ] || [ x"$num" = x"1" -a x"$BUILD_ID" = x"$id" ]
    then
	init

	info "Running build: \"$label\""

	run_tests "$cfg"
	if [ $? != 0 ]; then
	    exit $?
	fi
    fi

    id=$(($id + 1))
done

exit 0
