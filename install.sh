#!/bin/sh

BIN_DIR="$DESTDIR/usr/bin"
LIB_DIR="$DESTDIR/usr/lib/travis-run/"
SHARE_DIR="$DESTDIR/usr/share/travis-run/"

mkdir -p "$BIN_DIR"
mkdir -p "$SHARE_DIR/backends"
mkdir -p "$LIB_DIR"

replace_paths () {
    sed -r \
	-e 's|(export SHARE_DIR)=.*$|\1='"$SHARE_DIR"'|' \
	-e 's|(export LIB_DIR)=.*$|\1='"$LIB_DIR"'|'
}

replace_paths \
    < common.sh \
    > "$SHARE_DIR/common.sh"

replace_paths \
    < travis-run \
    > "$BIN_DIR/travis-run"
chmod +x "$BIN_DIR/travis-run"

cp -R \
    travis-run-create.sh \
    travis-run-run.sh \
    vm/ \
    docker/ \
    keys/ \
    script/ \
    "$SHARE_DIR"

cp lib/travis-run-getopt "$LIB_DIR"

for backend in backends/*.sh; do
    cp "$backend" "$SHARE_DIR/backends"
done
