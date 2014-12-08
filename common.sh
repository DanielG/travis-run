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

# Do not split this line. Also it will be replaced by the conrete version by
# install.sh so TRAVIS_RUN_VERSION can only be used to override VERSION during
# development
VERSION=${TRAVIS_RUN_VERSION:-$(cd "$(dirname "$0")" && sh install-version.sh || echo "(unknown)")}


export SHARE_DIR="$(dirname "$0")"
export LIB_DIR="$(dirname "$0")/lib"

if getopt -T >/dev/null 2>&1; then
    # Those silly BSDs need a proper getopt
    export GETOPT=$LIB_DIR/travis-run-getopt
else
    export GETOPT=getopt
fi

# on Debian docker's executable is called docker.io gah ...
if which docker.io >/dev/null; then
    alias docker=docker.io
fi

QUIET=0

################################################################################
# Utilities

strip_home () {
    home=$(echo "$HOME/" | sed 's|//|/|g')
    echo "$1" | sed "s|$home||"
}

lhead () {
    awk '{ print $1 }'
}

ltail () {
    sed -r 's/^[^[:space:]]+[[:space:]]*//'
}

trim () {
    sed -e 's/^ *//' -e 's/ *$//'
}

tca () {
    cat "$@" | trim
}

err2null () {
    if [ "$TRAVIS_RUN_DEBUG" ]; then
        eval "$@"
    else
        eval "$@" 2>/dev/null
    fi
}

info () {
    if [ "$QUIET" -lt 2 ]; then
	printf "$*\n" >&2
    fi
}

debug () {
    if [ "$TRAVIS_RUN_DEBUG" ]; then
	printf "$*\n" >&2
    fi
}

error () {
    printf "$*\n" >&2
}

feval () {
    local acc=""

    for t in "$@"; do
        case "$t" in
            ">"|"<"|";")
                acc="$acc $t" ;;
            *)
                acc="$acc \"$t\""
        esac
    done

    eval "$acc"
}

do_done () {
    [ "$QUIET" -lt 2 ] && printf "$1..." >&2 ; shift
    eval "$@"
    local rv=$?
    if [ $rv -ne 0 ]; then
	[ "$QUIET" -lt 2 ] && echo "failed!" >&2
	return $rv
    else
	[ "$QUIET" -lt 2 ] && echo "done" >&2
        return 0
    fi
}

# retry COUNT COMMAND [ARGS...]
retry () {
    count=$1; shift

    local rv

    while [ "$count" -gt 0 ]; do
	"$@"

	rv=$?
	if [ $rv -ne 0 ]; then
	    count=$(($count - 1))
	else
	    break
	fi

	sleep 0.1
    done

    return $rv
}

fifo () {
    rm -f "$1" && mkfifo "$1"
    if [ $? -ne 0 ]; then
        exit $?
    fi
}

################################################################################
# Backend stuff

backend_register_longopt () {
    if [ "$BACKEND_GETOPT_LONG" ]; then
	BACKEND_GETOPT_LONG="${BACKEND_GETOPT_LONG},$1"
    else
	BACKEND_GETOPT_LONG="$1"
    fi
}

BACKENDS=""
for b in $SHARE_DIR/backends/*.sh; do
    name=$(basename -s .sh "$b")
    BACKENDS="${BACKENDS} $name"
    . "$b"
done

##
# Initialize the backend, possibly starting VMs if required.
#
# Usage: backend_init VM_NAME
backend_init () {
    "${OPT_BACKEND}"_init "$@" $BACKEND_ARGS
}

##
# Finalize backend, this should 'clean up all resources allocated in
# `backend_init' i.e. stopping VMs started during init.
#
# Requirements for ${backend}_end:
#  - Multiple calls to `${backend}_end' MUST be ignored.
#  - If `${backend}_init' hasn't been called yet `${backend}_end' MUST be
#    ignored.
#
# Usage: backend_end VM_NAME
backend_end () {
    "${OPT_BACKEND}"_end "$@" $BACKEND_ARGS
}

##
# Check if a VM exists
#
# Usage: backend_vm_exists VM_NAME
backend_vm_exists () {
    "${OPT_BACKEND}"_vm_exists "$@" $BACKEND_ARGS
}

##
# Create a new VM image and configuration
#
# Usage: backend_create VM_NAME LANGUAGE
backend_create () {
    "${OPT_BACKEND}"_create "$@" $BACKEND_ARGS
}

##
# Stop VM and remove state from project directory
#
# Usage: backend_clean VM_NAME
backend_clean () {
    "${OPT_BACKEND}"_clean "$@" $BACKEND_ARGS
}

##
# Stop VM and remove all state from project directory and globally
#
# Usage: backend_destroy VM_NAME
backend_destroy () {
    "${OPT_BACKEND}"_destroy "$@" $BACKEND_ARGS
}

##
# Run travis-run-script in virtualized environment
#
## Usage: backend_run VM_NAME [OPTIONS..]
backend_run_script () {
    "${OPT_BACKEND}"_run_script "$@"
}

##
# Run Command in virtualized environment
#
# Preconditons: `backend_init' was called and `backend_end' has not been called
# yet
#
# Requirements for ${backend}_run:
#
#  - Contents of the CWD must be available inside the VM
#
## Usage: backend_run VM_NAME COPY? -- COMMAND
backend_run () {
    "${OPT_BACKEND}"_run "$@"
}
