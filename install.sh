#!/bin/sh

if [ ! "$1" ]; then
    echo "Usage: install.sh VERSION">&2
    exit 1
fi

VERSION="$1"
PREFIX=${PREFIX:-"/usr"}
BIN_DIR=${BIN_DIR:-"$PREFIX/bin"}
LIB_DIR=${LIB_DIR:-"$PREFIX/lib/travis-run/"}
SHARE_DIR=${SHARE_DIR:-"$PREFIX/share/travis-run/"}
MAN1_DIR=${MAN1_DIR:-"$PREFIX/share/man/man1"}

mkdir -p "$DESTDIR/$BIN_DIR"
mkdir -p "$DESTDIR/$SHARE_DIR/backends"
mkdir -p "$DESTDIR/$LIB_DIR"
mkdir -p "$DESTDIR/$MAN1_DIR"

install_script () {
    sed \
	-e 's|\(export SHARE_DIR\)=.*$|\1='"$SHARE_DIR"'|' \
	-e 's|\(export LIB_DIR\)=.*$|\1='"$LIB_DIR"'|' \
	-e 's|^\(VERSION\)=.*$|\1='"$VERSION"'|'
}

install_script \
    < common.sh \
    > "$DESTDIR/$SHARE_DIR/common.sh"

install_script \
    < travis-run \
    > "$DESTDIR/$BIN_DIR/travis-run"
chmod +x "$DESTDIR/$BIN_DIR/travis-run"

cp -R \
    travis-run-create.sh \
    travis-run-run.sh \
    vm \
    docker \
    keys \
    script \
    "$DESTDIR/$SHARE_DIR"

cp travis-run.1 "$DESTDIR/$MAN1_DIR"

cp lib/travis-run-getopt "$DESTDIR/$LIB_DIR"

for backend in backends/*.sh; do
    cp "$backend" "$DESTDIR/$SHARE_DIR/backends"
done
