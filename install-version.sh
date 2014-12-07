#!/bin/sh
set -e

cd "$(dirname "$0")"

if [ -e .git ]; then
    git describe
    else
    sed 's/Changes in \(.*\):/\1/g' < Changelog | head -n1
fi
