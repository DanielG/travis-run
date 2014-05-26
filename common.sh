#!/bin/sh

################################################################################
# Utilities

strip_home () {
    home=$(echo "$HOME/" | sed 's|//|/|g')
    echo $1 | sed "s|$home||"
}

head () {
    awk '{ print $1 }'
}

tail () {
    sed -r 's/^[^[:space:]]+[[:space:]]*//'
}

################################################################################
# Backend stuff

BACKENDS=""
for b in $(dirname $0)/backends/*; do
    name=$(basename -s .sh $b)
    BACKENDS="${BACKENDS} $name"
    . $b
done

##
# Initialize the backend, possibly starting VMs if required.
#
# Usage: backend_init VM_NAME
backend_init () {
    ${OPT_BACKEND}_init "$@" "$BACKEND_ARGS"
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
    ${OPT_BACKEND}_end "$@" "$BACKEND_ARGS"
}


##
# Create a new VM image and configuration
#
# MUST run prepare-vm.sh inside the vm after creating the vm
#
# Usage: backend_create VM_NAME
backend_create () {
    ${OPT_BACKEND}_create "$@" "$BACKEND_ARGS"
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
    ${OPT_BACKEND}_run "$@"
}
