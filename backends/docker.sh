backend_register_longopt "docker-base-image:"
backend_register_longopt "docker-build-stage:"
backend_register_longopt "docker-no-pull"

if [ x"$(uname)" = x"Darwin" ]; then
    debug "docker: Running on Darwin, using boot2docker."
    BOOT2DOCKER=true
else
    BOOT2DOCKER=false
fi

boot2docker_init () {
    [ -n "$DOCKER_HOST" ] && return
    if $BOOT2DOCKER; then
        if [ x"$(boot2docker status)" != x"running" ]; then
	    do_done "docker: Starting boot2docker VM (this might take a while)" \
	        err2null boot2docker up '>/dev/null'

	    [ $? -ne 0 ] && exit $?
        fi

        eval "export" $(boot2docker up 2>&1 \
	    | awk -n '/export DOCKER_HOST/{print $NF}')
    fi
}

# Input variables:
#     - $vm_name
docker_check_state_dir () {
    mkdir -p ~/.travis-run

    if [ ! -d ".travis-run/$vm_name" ]; then
	error "travis-run: Can't find state dir:"
	error "    $PWD/.travis-run/$vm_name"
	error
	error "Have you run \`travis-run create' yet?"
	exit 1
    fi
}

docker_exists () {
    docker inspect "$@" >/dev/null 2>&1
}

docker_tag_exists () {
    docker images --no-trunc \
        | awk '{ print $1 ":" $2 " " }' | trim | grep -q "^$*\$"
}


# Input variables:
#    - $opt_no_pull
docker_pull () {
    if [ "$opt_no_pull" ];  then
	return 1
    fi

    do_done "docker: trying to pull image $1" \
        docker pull "$@" >/dev/null 2>&1
    local rv=$?

    echo "$@" >> ~/.travis-run/images

    return $rv
}

# Usage: docker_build STAGE [COMMANDS...]
#
# Arguments:
#
#     - STAGE: this will be used to form the container tag using the template
#     - `$vm_repo:STAGE_$VERSION`
#
# Input variables:
#
#     - $VERSION
#     - $opt_stage
#     - $vm_repo
#     - $tmpdir: directory where `docker build` will be executed if a file
#       called `Dockerfile` exists in this directory it will be overwritten
#       unconditionally
#
# For examples see docker_create()
docker_build () {
    local stage_id=$1; shift

    if [ x"$stage_id" = x"language" ]; then
        local stage=$1; shift
    else
        local stage=$stage_id
    fi

    feval "$@"

    local sha
    sha=$(sha1sum $(find "$tmpdir" -type f) \
        | awk '{ print $1 }' \
        | sort \
        | sha1sum \
        | head -c10)

    local stage_tag="${vm_repo}:${stage}_$VERSION-${sha}"

    debug "docker_build: $stage_tag"

    while true; do
        if [ -n "$opt_stage" -a x"$opt_stage" != x"$stage_id" ]; then
            break
        fi

        if docker_tag_exists "$stage_tag"; then
            break
        elif ! docker_pull "$stage_tag"; then
	    docker build -t "$stage_tag" "$tmpdir" >&2 || return 1

            info "Built $stage_tag"

	    echo "$stage_tag" >> ~/.travis-run/images
        fi

        break
    done

    echo "$stage_tag"
}

docker_create () {
    boot2docker_init

    local opts="$($GETOPT -o "" --long docker-base-image:,docker-build-stage:,docker-no-pull -n "$(basename "$0")" -- "$@")"
    eval set -- "$opts"

    local opt_from opt_stage opt_no_pull

    while true; do
	case "$1" in
            --docker-base-image)  opt_from=$2;     shift; shift ;;
            --docker-build-stage) opt_stage=$2;    shift; shift ;;
	    --docker-no-pull)     opt_no_pull=1;   shift ;;

            --) shift; break ;;
            *) error "Error parsing argument: $1">&2; exit 1 ;;
	esac
    done

    local vm_repo="$1"; shift
    local vm_name="$(basename "$vm_repo")"

    local opt_language="$1"; shift
    local opt_from="${opt_from:-ubuntu:precise}"
    local opt_script_from="${opt_script_from:-debian:wheezy}"

    if [ ! "$opt_language" ]; then
	error "Usage: docker_create VM_NAME LANGUAGE [DOCKER_OPTIONS..]">&2
	exit 1
    fi

    tmpdir=$(mktemp -p "${TMPDIR:-/tmp/}" -d travis-run-XXXX) || exit 1
    trap 'rm -rf '"$tmpdir" 0

    cp -rp "$SHARE_DIR"/vm/*     "$tmpdir"
    cp -rp "$SHARE_DIR"/script   "$tmpdir"
    cp -p  "$SHARE_DIR"/keys/*   "$tmpdir"
    cp -p  "$SHARE_DIR"/docker/* "$tmpdir"

    local script_tag os_tag base_tag language_tag

    script_tag=$(docker_build "script" \
	info "Creating build-script image" \;\
	sed "s|%FROM%|${opt_script_from}|" \
           \< "$SHARE_DIR/docker/Dockerfile.script" \
	   \> "$tmpdir"/Dockerfile \;\
        )
    echo "$script_tag" > ".travis-run/$vm_name/docker-script-img"

    [ $? -eq 0 ] || return 1
    os_tag=$(docker_build "os" \
        info "Creating os image" \;\
        sed "s|%FROM%|${opt_from}|" \
	   \< "$SHARE_DIR/docker/Dockerfile.os" \
	   \> "$tmpdir"/Dockerfile \;\
        )

    [ $? -eq 0 ] || return 1
    base_tag=$(docker_build "base" \
	info "Creating base image" \;\
        sed "s|%FROM%|$os_tag|" \
           \< "$SHARE_DIR/docker/Dockerfile.base" \
           \> "$tmpdir"/Dockerfile \;\
        )

    [ $? -eq 0 ] || return 1
    language_tag=$(docker_build language "$opt_language" \
	info "Creating language image" \;\
	sed -e "s|%FROM%|$base_tag"'|' \
            -e "s|\%LANGUAGE%|$opt_language|" \
           \< "$SHARE_DIR/docker/Dockerfile.language" \
	   \> "$tmpdir"/Dockerfile \;\
        )

    if [ -z "$opt_stage" -o x"$opt_stage" = x"project" ]; then
        info
	info "Creating per-project image"
        info

	mkdir -p ".travis-run/$vm_name"

	if [ ! -e ".travis-run/$vm_name/Dockerfile" ] \
            || ! grep -q $language_tag < ".travis-run/$vm_name/"Dockerfile
        then
	    sed "s|%FROM%|$language_tag|" \
		< "$SHARE_DIR/docker/Dockerfile.project" \
		> ".travis-run/$vm_name"/Dockerfile
	fi

        fifo ".travis-run/.build-stdout"

        # Running in background so we can get the exit code
        docker build ".travis-run/$vm_name" \
            > ".travis-run/.build-stdout" &
        local build_pid=$!

	local docker_id="$(cat ".travis-run/.build-stdout" \
	    | grep 'Successfully built' \
	    | awk '{ print $3 }' \
            | trim)"

        wait $build_pid
        local rv=$?

        rm -f .travis-run/build-stdout

        if [ $rv -ne 0 ]; then
            return $rv
        fi

        if [ -z "$docker_id" ]; then
            error "\
travis-run: Error while building project container. Could not get resulting
container id, did `docker build`'s output format change?"
            exit 1
        fi

	echo "$docker_id" > ".travis-run/$vm_name/docker-project-img"
	echo "$docker_id" >> ~/.travis-run/images
    fi
}

docker_destroy () {
    docker_clean "$@"

    local images="$(sort < ~/.travis-run/images | uniq)"

    for img in $(printf '%s' "$images"); do
	if docker_exists "$img"; then
	    docker rmi $img

	    if [ $? -ne 0 ]; then
		local offender="$(docker ps -a \
                    | grep "$img" \
                    | awk '{ print $1 }')"

		if [ -n "$offender" ]; then
		    error "\
docker: Removing image \`$img' failed, looks like it's in use by container\n\
\`$offender'.\n\n\
If you're sure that container isn't doing anything important destroy it with:\n\
    $ docker stop $offender && docker rm $offender\n\
and run \`$0 destroy' again."
		else
		    error "\
docker: Removing image \`$img' failed, maybe some container is using it?\n\n\
Try \`docker ps -a' to find the running container and then \`docker {stop,rm}'\n\
to destroy the offending container."
		fi
		continue
	    fi
	fi
	images=$(printf '%s' "$images" | grep -v "^$img\$")
    done

    printf '%s' "$images" > ~/.travis-run/images
}

docker_clean () {
    local vm_repo="$1"; shift
    local vm_name="$(basename "$vm_repo")"

    if [ -f ".travis-run/$vm_name/docker-container-id" ]; then
	docker_end "$vm_repo"
    fi

    if [ -f ".travis-run/$vm_name/docker-project-img" ]; then
    	docker rmi "$(tca ".travis-run/$vm_name/docker-project-img")"
	rm -f ".travis-run/$vm_name/docker-project-img"
    fi
}

docker_vm_exists () {
    local vm_repo="$1"; shift
    local vm_name="$(basename "$vm_repo")"

    docker_check_state_dir

    [ -f ".travis-run/$vm_name/docker-project-img" ]
}

docker_init () {
    local vm_repo="$1"; shift
    local vm_name="$(basename "$vm_repo")"

    local docker_container_name="travis-run_$(printf '%s' "$PWD" |sed 's|/|-|g')"
    local docker_img_id="$(err2null tca ".travis-run/$vm_name/docker-project-img")"

    boot2docker_init || exit $?

    docker_check_state_dir

    if [ -n "$docker_img_id" ] && ! docker_exists "$docker_img_id"; then
        debug "docker: stale docker-project-img, removing"
        rm ".travis-run/$vm_name/docker-project-img"

        error "\
travis-run: The docker image ($docker_img_id) referenced in:\n\
	$PWD/.travis-run/$vm_name/docker-project-img\n\
could not be found.\n\
\n\
Please re-run \`travis-run create'.\n\
"
        exit 1
    fi

    if [ ! -f ".travis-run/$vm_name/docker-project-img" ]; then
	error "travis-run: Can't get docker image id."
	error
	error "Have you run \`travis-run create' yet?"
	exit 1
    fi

    while true; do
	if [ -f ".travis-run/$vm_name/docker-container-id" ]; then
	    debug "docker: try running container"
	    local docker_container_id
            docker_container_id=$(tca ".travis-run/$vm_name/docker-container-id")

	    local inspect running
	    inspect="$(docker inspect $docker_container_id)"
	    if [ $? -eq 0 ]; then
		running="$(printf '%s' "$inspect" \
                      | grep '"Running":[[:space:]]true')"

		if [ "$running" ]; then
		    info "docker: Using running container $docker_container_id"
		    break
		else
		    do_done "docker: Starting existing container" \
			docker start "$docker_container_id" >/dev/null
		    break
		fi
	    fi

	    debug "docker: nope, remove stale docker-container-id file"
	    rm ".travis-run/$vm_name/docker-container-id"
	    continue
	else
	    local listen
	    if ! $BOOT2DOCKER; then
		listen="127.0.0.1::"
	    else
		listen=""
	    fi

	    do_done "docker: Starting container from image $docker_img_id" \
		'docker_container_id=$(docker run -d -p ${listen}22 \
                               --name="$docker_container_name" "$docker_img_id")'

	    echo "$docker_container_id" \
                > ".travis-run/$vm_name/docker-container-id"

	    break
	fi
    done

    local addr ip port
    addr="$(docker port "$docker_container_id" 22)"
    if [ $? -ne 0 ]; then
	error "docker: getting port failed."
	exit 1
    fi

    ip=$(echo "$addr" | sed 's/:.*//')
    port=$(echo "$addr" | sed 's/.*://')

    if $BOOT2DOCKER; then
    	ip=$(boot2docker ip 2>/dev/null)

    	if [ $? -ne 0 ]; then
    	    error "docker: Couldn't get boot2docker VM ip address."
    	    exit 1
    	fi
    fi

    if [ ! -e ~/.travis-run/travis-run_id_rsa ]; then
	cp $SHARE_DIR/keys/travis-run_id_rsa     ~/.travis-run/
	cp $SHARE_DIR/keys/travis-run_id_rsa.pub ~/.travis-run/
	chmod 600 ~/.travis-run/travis-run_id_rsa
    fi

    local ssh_verbosity
    if [ "$TRAVIS_RUN_DEBUG" ]; then
        ssh_verbosity="-v"
    else
        ssh_verbosity="-q"
    fi

    # global on purpose, used by docker_run
    DOCKER_SSH="env LANGUAGE= LC_ALL= LC_CTYPE= LANG=C.UTF-8 ssh $ssh_verbosity -o CheckHostIP=no -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ConnectionAttempts=10 -o ControlMaster=no -i $HOME/.travis-run/travis-run_id_rsa -p $port travis@$ip"


    do_done "docker: Waiting for ssh to come up (this takes a while)" \
	retry 3 $DOCKER_SSH -Tn -- echo hai >/dev/null
}

docker_end () {
    local vm_repo="$1"; shift
    local vm_name="$(basename "$vm_repo")"

    [ ! -f ".travis-run/$vm_name/docker-container-id" ] && return

    local docker_container_id="$(tca ".travis-run/$vm_name/docker-container-id")"

    docker stop -t 0 "$docker_container_id" >/dev/null || true

    do_done "docker: Removing container $docker_container_id" \
	docker rm "$docker_container_id" >/dev/null || true

    rm -f ".travis-run/$vm_name/docker-container-id"
}

## Usage: docker_run_script VM_NAME [OPTIONS..]
docker_run_script () {
    local vm_repo="$1"; shift
    local vm_name="$(basename "$vm_repo")"

    boot2docker_init || exit $?

    docker_check_state_dir

    #"$vm_repo:script_$VERSION"
    local tag="$(cat .travis-run/$vm_name/docker-script-img)"

    if ! docker_tag_exists $tag; then
        error "\
travis-run: The docker image ($tag) could not be found.\n\
\n\
Please re-run \`travis-run create'.\
" >&2
        exit 1
    fi

    do_done "docker: Generating build script" \
	docker run --rm -i "$tag" "$@"
}

## Usage: docker_run VM_NAME COPY? [OPTIONS..] -- COMMAND
docker_run () {
    local opts="$($GETOPT -o "" -n "$(basename "$0")" -- "$@")"
    eval set -- "$opts"

    while [ x"$1" != x"--" ]; do shift; done; shift

    local vm_repo="$1"; shift
    local vm_name="$(basename "$vm_repo")"
    local cpy="$1"; shift

    docker_check_state_dir

    if [ x"$CPY" = x"copy" ]; then
	$DOCKER_SSH -nT -- "rm -rf 'build/' && mkdir -p build/"

	do_done "docker: Copying directory into container" \
	    \( git ls-files --exclude-standard --others --cached -z \
	    \| tar -c --null -T - \
	    \| $DOCKER_SSH -T -- tar -C build -x \)
    fi

    $DOCKER_SSH -- "$@"
}
