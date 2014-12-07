backend_register_longopt() { true; }

cd "$(dirname "$0")"

. ./common.sh

OPTS="--docker-no-pull"

docker_create $OPTS --docker-build-stage=script   dxld/travis-run any
docker_create $OPTS --docker-build-stage=base     dxld/travis-run any

LANGS=$(printf '%s\n' vm/templates/*.runlist
    | sed 's/.*worker\.\([^.]*\)\..*/\1/g')

for l in $LANGS; do
    docker_create $OPTS --docker-build-stage=language dxld/travis-run $l
done
