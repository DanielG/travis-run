travis-run
==========

travis-run creates virtual machines resembling the build environment provided by
the travis-ci.org continuous integration service. This is so one can run and
debug builds locally, which should take most of the guesswork out of fixing
problems that only occur on travis-ci but not on the developer's machine. To do
this, we use the same chef-solo cookbooks used by travis-ci and generate the
script to drive the build from the .travis.yml file using the ruby libraries
published by them.

Installation
============

Just add this directory to your *PATH*.

Usage
=====

- Create a virtual machine: `travis-run create`

  You should run this in your project directory.

  This will create a directory `.travis-run/` that will contain a *Dockerfile*
  which you may modify and commit to version control.

- Run your builds locally: `travis-run`

  This will create a new docker container, copy the build directory into the
  container and execute the build as it would be on travis-ci.

```
TRAVIS-RUN(1)                    User Commands                   TRAVIS-RUN(1)

NAME
       travis-run - Run travis-ci builds locally using Docker

SYNOPSIS
       travis-run [OPTIONS..] [BACKEND_OPTIONS..] [COMMAND [ARGS..]]

GLOBAL OPTIONS
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

              Arbitrary identifier associated with the build VM. (defaults to:
              travis-run-vm). The backend may support persistent  options  per
              VM referenced by name, see backend documentation for details.

COMMANDS
   run (default if no command given):
              Run  the build matrix in sequence and abort on the first failure
              dropping into a shell for diagnostics by default. Note  that  by
              default  the  project directory is also synchronized with the VM
              running the build before and after the build so make  sure  your
              .travis.yml  contains  a  `clean'  action  before attempting the
              build.

   stop:
              Stop running build VM. This will tear down the VM  as  well  as\
              all it's disk state.

   create:
              Setup  build  VM.  Depending  on  the backend it might be stored
              globally or in `.travis-run' in the current directory.

       --docker-base-image=BASE_IMAGE
              Docker image to use as the base for the  container,  see  `FROM'
              Dockerfile command.  (defaults to: ubuntu:presice)

       --docker-build-stage=STAGE
              Stage  of  the  image  build to run, (one of: base, script, lan‐
              guage, project)

   clean:
              Stop running build VM, and clean any backend specific state kept
              in the project directory.
```
