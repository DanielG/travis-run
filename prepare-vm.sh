#!/bin/sh
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

adduser $USER_
adduser $USER_ sudo || true

mkdir -p /home/$USER_
chown $USER_:$USER_ /home/$USER_
chmod 755 /home/$USER_

echo 'Defaults !authenticate' > /etc/sudoers.d/noauth
chmod 0440 /etc/sudoers.d/noauth

echo '{ "travis_build_environment": { "user": "'$USER_'", "group": "'$USER_'", "home": "/home/'$USER_'/" }' > travis.json

chef-solo --node-name $(hostname) -j travis.json -o haskell -o haskell::multi
