This project is abanoned and doesn't work anymore
=================================================



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

The simplest way to install *travis-run* is to just clone it and add the
resulting directory to your *PATH*:

```
$ git clone https://github.com/DanielG/travis-run.git
$ cd travis-run
$ git checkout $(git describe | awk -vFS=- '{ print $1 }') # chekout latest release
$ export PATH=$PATH:$PWD # also put that it in your shell's rc file
```

If you want to get more fancy the following installation methods are also
available:

Debian
------

```
# apt-get install devscripts
$ git clone https://github.com/DanielG/travis-run.git
$ cd travis-run
$ git checkout $(git describe | awk -vFS=- '{ print $1 }') # chekout latest release
$ debuild -uc -us
# dpkg -i ../travis-run_*.deb
```

OS X
----

Install *boot2docker* using the osx-installer from here: https://github.com/boot2docker/osx-installer/releases

**DONT** use the homebrew package for *boot2docker* (or at least you're on your
  own if you do) as I couldn't get it to work reliably with
  *travis-run*. Patches welcome etc. ;)

```
$ brew tap andy-morris/homebrew-extra
$ brew install travis-run
$ boot2docker init
```

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

If you just want to run a certain build, first see which ones are avalable:

```
$ travis-run matrix
docker: Generating build script...done
0: "ghc: 7.4"
1: "ghc: 7.6"
2: "ghc: 7.8"
```

Now pick one and use either the BUILD_ID in the first column or the BUILD_LABEL
in quotes to specify which one to build, like so:

```
$ travis-run run "ghc: 7.6"
docker: Generating build script...done
docker: Starting container from image adafd960790c...done
docker: Waiting for ssh to come up (this takes a while)...done
Running build: "ghc: 7.6"
docker: Copying directory into container...done
[...build runs...]
Build failed, please investigate.
Welcome to Ubuntu 12.04.4 LTS (GNU/Linux 3.14-1-amd64 x86_64)

 * Documentation:  https://help.ubuntu.com/
Last login: Tue Jul  1 02:34:20 2014 from 172.17.42.1
travis@8f5a20acf357:~$ ls
drwxrwxr-x 1 travis travis 298 Jul  1 02:36 build
travis@8f5a20acf357:~$
```

Once you're done debugging your problem just `exit` the shell.

IRC
===

If you have any problems, suggestions or comments swing by
[#travis-run](irc://chat.freenode.net/trais-run) on Freenode.

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

              Backend specific identifier associated with the VM.

              For  the  docker  backend  this  should  be in the form `REPOSI‐
              TORY/IMAGE'. This will be used to pull prebuilt container images
              too  as  to  tag  built  container images when prebuilts are not
              found. (defaults to `dxld/travis-run')

COMMANDS
   run [BUILD_ID | BUILD_CONFIG]:
              (default if no command given) Run the build matrix  in  sequence
              and  abort  on  the first failure or run the given BUILD_ID (see
              the `matrix' command). On failure you will  be  dropped  into  a
              shell  inside the build environment so you can figure out what's
              going on.

       --shell
              Prepare for a build but instead of running it launch a shell.

   stop:
              Stop running build VM. This will tear down the VM as well as all
              it's disk state.

   create:
              Setup  build  VM.  Depending  on  the backend it might be stored
              globally or in `.travis-run' in the current directory.

       --docker-base-image=BASE_IMAGE
              Docker image to use as the base for the  container,  see  `FROM'
              Dockerfile command.  (defaults to: ubuntu:presice)

       --docker-build-stage=STAGE
              Stage of the image build to run, (one of: os, base, script, lan‐
              guage, project)

       --docker-no-pull
              Build all docker containers from scratch, don't try to pull them
              from the docker hub.

   clean:
              Stop running build VM, and clean any backend specific state kept
              in the project directory.

   matrix:
              Print the build matrix. The number in the first  column  is  the
              BUILD_ID.  The part after the ':' is the BUILD_CONFIG, note that
              this is whitespace sensitive.



travis-run 0.1                   December 2014                   TRAVIS-RUN(1)
```
