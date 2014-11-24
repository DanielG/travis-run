backend_register_longopt() { true; }

cd "$(dirname "$0")"

. ./common.sh

docker_create --docker-no-pull --docker-build-stage=script   dxld/travis-run any
docker_create --docker-no-pull --docker-build-stage=base     dxld/travis-run any
docker_create --docker-no-pull --docker-build-stage=language dxld/travis-run haskell
docker_create --docker-no-pull --docker-build-stage=language dxld/travis-run php
