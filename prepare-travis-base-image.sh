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
RECIPE=$2

if [ ! $USER_ ]; then
    exit 1
fi

echo 'APT::Get::Assume-Yes "true";' > /etc/apt/apt.conf.d/00assume-yes

apt-get update

apt-get install \
    sudo git rsync \
    rubygems ruby-dev \
    python-software-properties

if [ ! "$(gem list --local | grep "^chef" )" ]; then
    gem install --no-ri --no-rdoc chef
fi

git clone https://github.com/travis-ci/travis-cookbooks.git travis-cookbooks

mkdir -p /var/chef/cookbooks
cp -a travis-cookbooks/ci_environment/* /var/chef/cookbooks

mkdir -p /etc/chef/
cat > /etc/chef/solo.rb <<EOF
# Verify all HTTPS connections (recommended)
ssl_verify_mode :verify_peer

# OR, Verify only connections to chef-server
verify_api_cert true
EOF

adduser $USER_ --disabled-password --gecos ""
adduser $USER_ sudo || true

mkdir -p /home/$USER_
chown $USER_:$USER_ /home/$USER_
chmod 755 /home/$USER_

echo 'Defaults !authenticate' > /etc/sudoers.d/noauth
chmod 0440 /etc/sudoers.d/noauth
