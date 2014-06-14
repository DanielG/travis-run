#!/bin/sh

BIN_DIR="/usr/bin"
LIB_DIR="/usr/lib/travis-run/"
SHARE_DIR="/usr/share/travis-run/"
MAN1_DIR="/usr/share/man/man1"

mkdir -p "$DESTDIR/$BIN_DIR"
mkdir -p "$DESTDIR/$SHARE_DIR/backends"
mkdir -p "$DESTDIR/$LIB_DIR"
mkdir -p "$DESTDIR/$MAN1_DIR"

replace_paths () {
    sed -r \
	-e 's|(export SHARE_DIR)=.*$|\1='"$SHARE_DIR"'|' \
	-e 's|(export LIB_DIR)=.*$|\1='"$LIB_DIR"'|'
}

replace_paths \
    < common.sh \
    > "$DESTDIR/$SHARE_DIR/common.sh"

replace_paths \
    < travis-run \
    > "$DESTDIR/$BIN_DIR/travis-run"
chmod +x "$DESTDIR/$BIN_DIR/travis-run"

cp -R \
    travis-run-create.sh \
    travis-run-run.sh \
    vm/ \
    docker/ \
    keys/ \
    script/ \
    "$DESTDIR/$SHARE_DIR"

cp travis-run.1 "$DESTDIR/$MAN1_DIR"

cp lib/travis-run-getopt "$DESTDIR/$LIB_DIR"

for backend in backends/*.sh; do
    cp "$backend" "$DESTDIR/$SHARE_DIR/backends"
done
