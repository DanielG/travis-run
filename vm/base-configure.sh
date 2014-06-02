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

# run inside the virtualized environment as root for setup
set -e

USER_=$1

if [ ! $USER_ ]; then
    exit 1
fi

mkdir -p /etc/chef/
cat > /etc/chef/solo.rb <<EOF
ssl_verify_mode :verify_peer
verify_api_cert true
EOF

adduser "$USER_" --disabled-password --gecos ""
adduser "$USER_" sudo || true

mkdir -p /home/"$USER_"
chown "$USER_":"$USER_" /home/"$USER_"
chmod 755 /home/"$USER_"

mkdir /home/"$USER_"/.ssh
chmod 700 /home/"$USER_"/.ssh
chown -R "$USER_":"$USER_"  /home/"$USER_"/.ssh
cat /root/travis-run.pub >> /home/"$USER_"/.ssh/authorized_keys

echo 'Defaults !authenticate' > /etc/sudoers.d/noauth
chmod 0440 /etc/sudoers.d/noauth

echo '{ "travis_build_environment": { "user": "'"$USER_"'", "group": "'"$USER_"'", "home": "/home/'"$USER_"'/" }' > /root/travis.json
