#!/bin/sh
# Copyright (C) 2014  Daniel Gröber <dxld ÄT darkboxed DOT org>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

LANGUAGE=$1; shift
USER_=$1; shift

if [ ! "$LANGUAGE" ] || [ ! "$USER_" ]; then
    echo "Usage: $0 LANGUAGE USER">&2
    exit 1
fi

# Use https://github.com/travis-ci/travis-images/tree/master/templates as a
# reference for runlists for other languages.

printf '{
    "travis_build_environment": {
        "user": "'"$USER_"'",
        "group": "'"$USER_"'",
        "home": "/home/'"$USER_"'/"
    }' > travis.json

case "$LANGUAGE" in
    haskell) RUNLIST="-o haskell::multi,sweeper" ;;
    php) RUNLIST="-o php::multi,composer,sweeper"
         apt-get install m4
        ;;
    *)
        echo; echo; echo
	echo "Warning: Untested language: $LANGUAGE"
        echo; echo; echo
	RUNLIST="$LANGUAGE"
	;;
esac

printf '}' >> travis.json

chef-solo --node-name $(hostname) -j travis.json $RUNLIST
