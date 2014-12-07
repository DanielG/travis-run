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



RUNLIST=$(cat worker.$LANGUAGE.yml.runlist)

JSON=worker.$LANGUAGE.yml.json

cat > tbe.json <<EOF
{
    "travis_build_environment": {
        "user": "$USER_",
        "group": "$USER_",
        "home": "/home/$USER_/",
        "use_tmpfs_for_builds": "false"
    }
}
EOF
if [ -e $JSON ]; then
    jq -s '.[0] * .[1]' $FILE - < worker.go.yml.json > travis.json
else
    cp tbe.json travis.json
fi

echo >&2
echo travis.json: >&2
cat travis.json >&2

chef-solo --node-name $(hostname) -j travis.json -o "$RUNLIST"
