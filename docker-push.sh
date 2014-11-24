#!/bin/sh

if [ -z "$1" ]; then
    echo "Usage: $0 VERSION"
    exit 1
fi

# on Debian docker's executable is called docker.io gah ...
if which docker.io >/dev/null; then
    alias docker=docker.io
fi

docker login
docker push dxld/travis-run:script_$1
docker push dxld/travis-run:haskell_$1
docker push dxld/travis-run:php_$1
docker push dxld/travis-run:base_$1
rm -f ~/.dockercfg
