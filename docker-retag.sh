#!/bin/sh

if [ -z "$1" -o -z "$2" ]; then
    echo "Usage: $0 OLD_VERSION NEW_VERSION"
    exit 1
fi

VERSION=$(cd "$(dirname "$0")" && git describe || echo "(unknown)")

# on Debian docker's executable is called docker.io gah ...
if which docker.io >/dev/null; then
    alias docker=docker.io
fi

base=$(docker images | grep base_$1 | awk '{ print $3 }')
script=$(docker images | grep script_$1 | awk '{ print $3 }')
haskell=$(docker images | grep haskell_$1 | awk '{ print $3 }')

docker tag $base     dxld/travis-run:base_$2
docker tag $script   dxld/travis-run:script_$2
docker tag $haskell  dxld/travis-run:haskell_$2
