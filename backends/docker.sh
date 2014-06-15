backend_register_longopt "docker-base-image:"
backend_register_longopt "docker-build-stage:"

docker_check_state_dir () {
    if [ ! -d ".travis-run/$VM_NAME" ]; then
	echo "travis-run: Can't find state dir: ">&2
	echo "    $PWD/.travis-run/$VM_NAME">&2
	echo >&2
	echo "Have you run \`travis-run create' yet?">&2
	exit 1
    fi
}

docker_create () {
    set -e

    local OPTS VM_NAME LANGUAGE OPT_DISTRIBUTION OPT_FROM OPT_STAGE

    OPTS=$($GETOPT -o "" --long docker-base-image:,docker-build-stage: -n "$(basename "$0")" -- "$@")
    eval set -- "$OPTS"

    while true; do
	case "$1" in
            --docker-base-image)  OPT_FROM=$2;     shift; shift ;;
            --docker-build-stage) OPT_STAGE=$2;    shift; shift ;;

            --) shift; break ;;
            *) echo "Error parsing argument: $1">&2; exit 1 ;;
	esac
    done

    VM_NAME=$1; shift
    OPT_LANGUAGE=$1; shift
    OPT_FROM=${OPT_FROM:-ubuntu:precise}

    if [ ! "$OPT_LANGUAGE" ]; then
	echo "Usage: docker_create VM_NAME LANGUAGE [DOCKER_OPTIONS..]">&2
	exit 1
    fi

    echo "Creating build-script image">&2
    (
	[ "$OPT_STAGE" -a "$OPT_STAGE" != "script" ] && exit

	mkdir -p ~/.travis-run/"${VM_NAME}_script"
	rm -rf ~/.travis-run/"${VM_NAME}_script"/script
	cp -rp "$SHARE_DIR/script"              ~/.travis-run/"${VM_NAME}_script"
	cp -p "$SHARE_DIR/keys/travis-run.pub"  ~/.travis-run/"${VM_NAME}_script"

	sed "s/\$FROM/${VM_NAME}_base"'/' \
	    < "$SHARE_DIR/docker/Dockerfile.script" \
	    > ~/.travis-run/"${VM_NAME}_script"/Dockerfile

	docker build -t "${VM_NAME}_script" ~/.travis-run/"${VM_NAME}_script"

    )

    echo "Creating base image"
    (
	[ "$OPT_STAGE" -a "$OPT_STAGE" != "base" ] && exit

	mkdir -p ~/.travis-run/"${VM_NAME}_base"
	cp -p "$SHARE_DIR/vm/base-install.sh"     ~/.travis-run/"${VM_NAME}_base"
	cp -p "$SHARE_DIR/vm/base-configure.sh"   ~/.travis-run/"${VM_NAME}_base"
	cp -p "$SHARE_DIR/keys/travis-run.pub"    ~/.travis-run/"${VM_NAME}_base"

	sed "s/\$OPT_FROM/$OPT_FROM"'/' \
	    < "$SHARE_DIR/docker/Dockerfile.base" \
	    > ~/.travis-run/"${VM_NAME}_base"/Dockerfile

	docker build --rm=false -t "${VM_NAME}_base" \
	    ~/.travis-run/"${VM_NAME}_base"
    )

    echo "Creating language image"
    (
	[ "$OPT_STAGE" -a "$OPT_STAGE" != "language" ] && exit

	mkdir -p ~/.travis-run/"${VM_NAME}_$OPT_LANGUAGE"
	cp -p "$SHARE_DIR/vm/language-install.sh" \
	    ~/.travis-run/"${VM_NAME}_$OPT_LANGUAGE"

	sed "s/\$FROM/${VM_NAME}_base"'/' \
	    < "$SHARE_DIR/docker/Dockerfile.language" \
	    > ~/.travis-run/"${VM_NAME}_$OPT_LANGUAGE"/Dockerfile
	sed -i "s/\$OPT_LANGUAGE/$OPT_LANGUAGE"'/' \
	    ~/.travis-run/"${VM_NAME}_$OPT_LANGUAGE"/Dockerfile

	docker build -t "${VM_NAME}_$OPT_LANGUAGE" \
	    ~/.travis-run/"${VM_NAME}_$OPT_LANGUAGE"
    )

    echo "Creating per-project image"
    (
	[ "$OPT_STAGE" -a "$OPT_STAGE" != "project" ] && exit

	mkdir -p ".travis-run/$VM_NAME"

	if [ ! -e ".travis-run/$VM_NAME/Dockerfile" ]; then
	    sed "s/\$FROM/${VM_NAME}_$OPT_LANGUAGE/" \
		< "$SHARE_DIR/docker/Dockerfile.project" \
		> .travis-run/"$VM_NAME"/Dockerfile
	fi

	DOCKER_ID=$(docker build ".travis-run/$VM_NAME" 2>/dev/null \
	    | grep 'Successfully built' \
	    | awk '{ print $3 }')

	echo "$DOCKER_ID" > ".travis-run/$VM_NAME/docker-image-id"
    )
}

docker_init () {
    local VM_NAME DOCKER_IMG_ID DOCKER_ID
    VM_NAME=$1; shift

    docker_check_state_dir "$VM_NAME"

    DOCKER_IMG_ID=$(cat ".travis-run/$VM_NAME/docker-image-id")

    echo -n "docker: Starting container..."
    DOCKER_ID=$(docker run -d -p 127.0.0.1::22 "$DOCKER_IMG_ID")

    if [ ! "$DOCKER_ID" ]; then
	echo "failed!">&2
	exit 1
    else
	echo "done">&2
    fi

    echo "$DOCKER_ID" > ".travis-run/$VM_NAME/docker-container-id"
}

docker_end () {
    set -e

    local VM_NAME DOCKER_ID
    VM_NAME=$1; shift

    docker_check_state_dir "$VM_NAME"

    if [ ! -f ".travis-run/$VM_NAME/docker-container-id" ]; then
	echo "docker: .travis-run/$VM_NAME/docker-container-id not found."
	exit 1
    fi

    DOCKER_ID=$(cat ".travis-run/$VM_NAME/docker-container-id")

    echo -n "docker: Stopping container...">&2
    docker stop "$DOCKER_ID" >/dev/null
    echo -n "done">&2

    echo -n "docker: Removing container...">&2
    docker rm "$DOCKER_ID" >/dev/null
    echo "done">&2

    rm ".travis-run/$VM_NAME/docker-container-id"
}

## Usage: docker_run_script VM_NAME [OPTIONS..]
docker_run_script () {
    local VM_NAME
    VM_NAME=$1; shift

    docker run --rm=true -i "${VM_NAME}_script" "$@"
}

## Usage: docker_run VM_NAME COPY? [OPTIONS..] -- COMMAND
docker_run () {
    local OPTS VM_NAME CPY DIR DOCKER_ID

    OPTS=$($GETOPT -o "" -n "$(basename "$0")" -- "$@")
    eval set -- "$OPTS"

    while [ x"$1" != x"--" ]; do shift; done; shift

    VM_NAME=$1; shift
    CPY=$1; shift

    docker_check_state_dir "$VM_NAME"

    if [ ! -e ~/.travis-run/travis-run_id_rsa ]; then
	cp $SHARE_DIR/keys/travis-run_id_rsa     ~/.travis-run/
	cp $SHARE_DIR/keys/travis-run_id_rsa.pub ~/.travis-run/
	chmod 600 ~/.travis-run/travis-run_id_rsa
    fi

    DOCKER_ID=$(cat ".travis-run/$VM_NAME/docker-container-id")

    local dir=$PWD addr ip port SSH
    addr=$(docker port "$DOCKER_ID" 22)
    ip=$(echo "$addr" | sed 's/:.*//')
    port=$(echo "$addr" | sed 's/.*://')

    SSH="ssh -q travis@$ip -p $port -i $HOME/.travis-run/travis-run_id_rsa -o CheckHostIP=no -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ConnectionAttempts=10"

    if [ x"$CPY" = x"copy" ]; then
	$SSH -nT -- mkdir -p build/

	git ls-files -X .gitignore --exclude-standard -oc -z \
	    | tar -C "$dir" -c --null -T - \
	    | $SSH -T -- tar -C build -x
    fi

    $SSH -- "$@"
}
