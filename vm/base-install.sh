#!/bin/sh
echo 'APT::Get::Assume-Yes "true";' > /etc/apt/apt.conf.d/00assume-yes

apt-get update

apt-get install \
    sudo git rsync wget \
    rubygems ruby-dev \
    python-software-properties

gem install --no-ri --no-rdoc bundler
bundler install --binstubs

wget -O - https://github.com/travis-ci/travis-cookbooks/archive/master.tar.gz | tar -xz
mkdir -p /var/chef/cookbooks
cp -a travis-cookbooks-master/ci_environment/* /var/chef/cookbooks

printf '{
    "travis_build_environment": {
        "user": "'"$USER_"'",
        "group": "'"$USER_"'",
        "home": "/home/'"$USER_"'/",
        "use_tmpfs_for_builds": "false"
    },

    "rvm": {
        "default": "1.9.3",
        "rubies": { "name": "1.9.3" },
        "gems":   ["bundler", "rake"]
    },

    "golang": {
        "multi": {
            "versions": ["go1.3.3"],
            "aliases": [],
            "default_version": "go1.3.3"
        }
  }
}
' > travis.json

# derived from https://github.com/travis-ci/travis-images/blob/master/templates/worker.standard.yml @ 0cfd6c255627b4b792962971d5ec37038a46e68b
RUNLIST='travis_build_environment,apt,package-updates,build-essential,clang::tarball,golang::multi,networking_basic,openssl,sysctl,git::ppa,mercurial,bazaar,subversion,scons,unarchivers,md5deep,dictionaries,jq,libqt4,libgdbm,libncurses,libossp-uuid,libffi,ragel,imagemagick,mingw32,libevent,java,ant,maven,sqlite,rvm,rvm::multi,python,python::devshm,python::pip,nodejs::multi,mysql::server_on_ramfs,postgresql,redis,riak,mongodb,couchdb::ppa,memcached,neo4j-server::tarball,cassandra::tarball,rabbitmq::with_management_plugin,zeromq::ppa,elasticsearch,sphinx::all,xserver,firefox::tarball,chromium,phantomjs::tarball,emacs::nox,vim,system_info,sweeper'

chef-solo --node-name $(hostname) -j travis.json -o "$RUNLIST"
