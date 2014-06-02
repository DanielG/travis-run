#!/bin/sh

mkdir -p "$DESTDIR/usr/share/travis-run/"
mkdir -p "$DESTDIR/usr/share/travis-run/backends"
mkdir -p "$DESTDIR/usr/bin/"

# $(dirname $0)/backends/* -> /usr/share/travis-run/backends/*
# $(dirname $0)/* -> /usr/share/travis-run/*

for f in travis-run travis-run-create; do
    sed -e 's|$(dirname $0)/|/usr/share/travis-run/|g' \
	< "$f" \
	> "$DESTDIR/usr/bin/$f"
    chmod +x "$DESTDIR/usr/bin/$f"
done

cp travis-run-script "$DESTDIR/usr/bin/" \
    && chmod +x "$DESTDIR/usr/bin/travis-run-script"

for f in common.sh backends/*.sh; do
    sed -e 's|$(dirname $0)/|/usr/share/travis-run/|g' \
	< "$f" \
	> "$DESTDIR/usr/share/travis-run/$f"
done
