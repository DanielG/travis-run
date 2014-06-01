#!/bin/sh
echo 'APT::Get::Assume-Yes "true";' > /etc/apt/apt.conf.d/00assume-yes

apt-get update

apt-get install \
    sudo git rsync wget \
    rubygems ruby-dev \
    python-software-properties

gem install --no-ri --no-rdoc chef

(
    cd /root/script
    mkdir gems
    export GEM_HOME=$PWD/gems
    export GEM_PATH=$PWD/gems
    bundle install
)

wget -O - https://github.com/travis-ci/travis-cookbooks/archive/master.tar.gz | tar -xz
mkdir -p /var/chef/cookbooks
cp -a travis-cookbooks-master/ci_environment/* /var/chef/cookbooks
