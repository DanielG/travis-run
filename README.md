travis-run
==========

*travis-run* creates virtual machines resembling the build environment provided
by the *travis-ci.org* continuous integration service. This is so one can run
and debug builds locally, which should take most of the guesswork out of fixing
problems that only occur on travis-ci but not on the developer's machine. To do
this, we use the same chef-solo cookbooks used by travis-ci and generate the
script to drive the build from the .travis.yml file using the ruby libraries
published by them.

Installation
============

The simplest way to install *travis-run* is to just `git clone
https://github.com/DanielG/travis-run.git` and add the resulting directory to
your *PATH*.

If you want to get more fancy the following installation methods are also
available:

Debian
------

```
# apt-get install devscripts
$ git clone https://github.com/DanielG/travis-run.git
$ cd travis-run
$ debuild -uc -us
# dpkg -i ../travis-run_*.deb
```

OS X
----

```
$ brew tap andy-morris/homebrew-extra
$ brew install travis-run
$ boot2docker init
```

Before you use travis-run you have to run `boot2docker up` and export
`DOCKER_HOST` as instructed.

Usage
=====

- Create a virtual machine: `travis-run create`

  You should run this in your project directory.

  This will create a directory `.travis-run/` that will contain a *Dockerfile*
  which you may modify and commit to version control.

- Run your builds locally: `travis-run`

  This will create a new docker container, copy the build directory into the
  container and execute the build as it would be on travis-ci. Different
  configurations (i.e. different runtime versions/`env` variables) will be run
  one after another.


Man Page
========
```
TRAVIS-RUN(1)                    User Commands                   TRAVIS-RUN(1)



NAME
       travis-run - Run travis-ci builds locally using Docker

SYNOPSIS
       travis-run [OPTIONS..] [BACKEND_OPTIONS..] [COMMAND [ARGS..]]

GLOBAL OPTIONS
       -h, --help

              display this help and exit

       --version

              Display version information and exit

       -b, --backend=BACKEND

              Virtualization  backend  to  use.  Currently  available backends
              (defaults to: docker):

              - docker

       -k, --keep

              Don't stop and destroy VM after build finishes. This  is  useful
              during  development  as you will only have to go through VM cre‐
              ation once. Make sure to `travis-run clean' or `travis-run stop'
              after you're done with the VM.

       -n, --vm-name=VM_NAME

              Backend  specific  identifier  associated  with  the VM. For the
              docker backend this is the repository name  for  the  images  to
              use. (defaults to `dxld/travis-run' for docker backend)

COMMANDS
   run [BUILD_ID | BUILD_CONFIG]:
              (default  if  no command given) Run the build matrix in sequence
              and abort on the first failure or run the  given  BUILD_ID  (see
              the  `matrix'  command).  On  failure you will be dropped into a
              shell inside the build environment so you can figure out  what's
              going on.

       --shell
              Prepare for a build but instead of running it launch a shell.

   stop:
              Stop running build VM. This will tear down the VM as well as all
              it's disk state.

   create:
              Setup build VM. Depending on the  backend  it  might  be  stored
              globally or in `.travis-run' in the current directory.

       --docker-base-image=BASE_IMAGE
              Docker  image  to  use as the base for the container, see `FROM'
              Dockerfile command.  (defaults to: ubuntu:presice)

       --docker-build-stage=STAGE
              Stage of the image build to run, (one  of:  base,  script,  lan‐
              guage, project)

       --docker-no-pull
              Build all docker containers from scratch, don't try to pull them
              from the docker hub.

   clean:
              Stop running build VM, and clean any backend specific state kept
              in the project directory.

   matrix:
              Print  the  build  matrix. The number in the first column is the
              BUILD_ID. The part after the ':' is the BUILD_CONFIG, note  that
              this is whitespace sensitive.



travis-run 0.1                     June 2014                     TRAVIS-RUN(1)
```
