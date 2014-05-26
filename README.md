travis-run
==========

Run *travis-ci* build locally with *schroot* or *Vagrant*+*Docker*.

Installation
============

For now you should just clone https://github.com/DanielG/travis-run.git, run
`bundle install` in there and add the directory it to your *PATH*.

Usage
=====

- Pick your backend

  For regular use the `vagrant` backend is recommended.

- Create a virtual machine: `travis-run-create -b vagrant`

  With the `vagrant` backend this involves doing a `docker build` inside the
  Host VM or on the system running `travis-run-create` (with Linux).

- Run your builds locally: `travis-run -b vagrant`

  This will spin up the Vagrant Host VM if needed, create a new docker
  container, copy the build directory into the container and execute the build
  as it would be on travis-ci.
