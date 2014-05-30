#!/bin/sh

backend_register_longopt "docker-base-image:"

docker_check_state_dir () {
    if [ ! -d .travis-run/$VM_NAME ]; then
	echo "travis-run: Can't find state dir: ">&2
	echo "\t$PWD/.travis-run/$VM_NAME">&2
	echo >&2
	echo "Have you run \`travis-run create' yet?">&2
	exit 1
    fi
}

docker_create () {
    set -e

    local OPTS VM_NAME LANGUAGE OPT_DISTRIBUTION OPT_FROM

    OPTS=$($GETOPT -o "" --long docker-base-image: -n "$(basename $0)" -- "$@")
    eval set -- "$OPTS"

    while true; do
	case "$1" in
            --docker-base-image)  OPT_FROM=$1;     shift; shift ;;

            --) shift; break ;;
            *) echo "Error parsing argument: $1">&2; exit 1 ;;
	esac
    done

    VM_NAME=$1; shift
    OPT_LANGUATE=$1; shift
    OPT_FROM=${OPT_FROM:-ubuntu:precise}; shift

    if [ ! $OPT_LANGUAGE ]; then
	echo "Usage: docker_create VM_NAME LANGUAGE [DOCKER_OPTIONS..]">&2
	exit 1
    fi

    ## Create base image
    (
	mkdir -p ~/.travis-run/${VM_NAME}_base
	cd ~/.travis-run/${VM_NAME}_base
	cp $SHARE_DIR/prepare-travis-base-image.sh .
	cp $SHARE_DIR/prepare-travis-language-image.sh .

	sed 's/$OPT_FROM/'"$OPT_FROM"'/' \
	    < $SHARE_DIR/docker/Dockerfile.base > Dockerfile

	docker build -t ${VM_NAME}_base .
    )

    ## Create language image
    (
	mkdir -p ~/.travis-run/${VM_NAME}_$OPT_LANGUAGE
	cd ~/.travis-run/${VM_NAME}_$OPT_LANGUAGE

	sed 's/$FROM/'"${VM_NAME}_base"'/' \
	    < $SHARE_DIR/docker/Dockerfile.language > Dockerfile
	sed -i 's/$OPT_LANGUAGE/'"$OPT_LANGUAGE"'/' Dockerfile

	docker build -t ${VM_NAME}_$OPT_LANGUAGE .
    )

    ## Create per-project image
    (
	mkdir -p .travis-run/$VM_NAME
	cd .travis-run/$VM_NAME

	if [ ! -e Dockerfile ]; then
	    sed 's/$FROM/'"${VM_NAME}_$OPT_LANGUAGE"'/' \
		< $SHARE_DIR/docker/Dockerfile.template > Dockerfile
	fi

	DOCKER_ID=$(docker build . 2>/dev/null \
	    | grep 'Successfully built' \
	    | awk '{ print $3 }')

	echo $DOCKER_ID > docker-image-id
    )
}

docker_init () {
    local VM_NAME DOCKER_ID
    VM_NAME=$1; shift

    docker_check_state_dir $VM_NAME

    DOCKER_ID=$(docker run -d -P)
    echo $DOCKER_ID > .travis-run/$VM_NAME/docker-container-id
}

docker_end () {
    set -e

    local VM_NAME DOCKER_ID
    VM_NAME=$1; shift

    docker_check_state_dir $VM_NAME

    if [ ! -f .travis-run/$VM_NAME/docker-id ]; then
	return
    fi

    DOCKER_ID=$(cat .travis-run/$VM_NAME/docker-container-id)

    docker stop $DOCKER_ID
    docker rm $DOCKER_ID

    rm .travis-run/$VM_NAME/docker-container-id
}

## Usage: vagrant_run VM_NAME COPY? [OPTIONS..] -- COMMAND
vagrant_run () {
    set -e

    local OPTS VM_NAME CPY DIR DOCKER_ID

    OPTS=$($GETOPT -o "" -n "$(basename $0)" -- "$@")
    eval set -- "$OPTS"

    while [ x"$1" != x"--" ]; do shift; done

    VM_NAME=$1; shift
    CPY=$1; shift

    docker_check_state_dir $VM_NAME

    DOCKER_ID=$(cat .travis-run/$VM_NAME/docker-container-id)

    docker port $DOCKER_ID 22

    exit 1

    local dir=$PWD
    (
	cd .travis-run/$VM_NAME

	if [ x"$CPY" = x"copy" ]; then
	    vagrant ssh -- mkdir -p build/
	    tar -C $dir -c . | vagrant ssh -- tar -C build -x
	    echo
	fi

	vagrant ssh -- "$@"
    )
}
