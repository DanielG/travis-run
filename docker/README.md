Dockerfiles for the "docker" backend
====================================

- Dockerfile.base

  To build the base image `prepare-travis-base-image.sh` will be run. It will
  set up the overall system environment as a travis worker VM. No language
  specific configuration will be done.

- Dockerfile.language

  The language specific images are built from this Dockerfile. This includes
  running `prepare-travis-language-image.sh` during the image build, it will run
  the travis-cookbooks appropriate for the given language.

- Dockerfile.template

  This Dockerfile will be copied to `.travis-run/$VM_NAME` in the user's project
  directory. The resulting file can be edited by the user to customize the
  environment, possibly for speeding up builds by pre-installing dependencies.
