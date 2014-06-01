travis-run
==========

Run *travis-ci* builds locally using *Docker*.

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
Usage: ./travis-run [OPTIONS..] [BACKEND_OPTIONS..] [COMMAND [ARGS..]]
Global Options (OPTIONS):
	-b, --backend=BACKEND
		Virtualization backend to use. Currently avalialbe backends:
		  docker
		(defaults to: docker)
	-k, --keep
		Do not stop and destroy VM after build finishes. This is useful
		during development as you will only have to go through
		VM creation once. Make sure to `travis-run clean' or
		`travis-run stop' after you're done with the VM.
	-n, --vm-name=VM_NAME
		Arbitrary identifier associated with the build VM. (defaults
		to: travis-run-vm). The backend may support persistent options
		per VM referenced by name, see backend documentation for
		details.


Global Backend Options (BACKEND_OPTIONS):
	None so far, see Commands for command specific backend options.


Commands (COMMAND):
	run (default if no command given)
		Run the build matrix in sequence and abort on the first failure
		dropping into a shell for diagnostics by default. Note that by
		default the project directory is also synchronized with the VM
		running the build before and after the build so make sure your
		.travis.yml contains a `clean' action before attempting the
		build.


	stop
		Stop running build VM. This will tear down the VM as well as
		all it's disk state.


	create
		Setup build VM. Depending on the backend it might be stored
		globally or in `.travis-run' in the current directory.
		Backend Options for `docker':
			--docker-base-image=BASE_IMAGE
				Docker image to use as the base for the
				container, see `FROM' Dockerfile command.
				(defaults to: ubuntu:presice)
			--docker-build-stage=STAGE
				Stage of the image build to run, can be one of:
				base, script, language, project


	clean
		Stop running build VM, and clean any backend specific state
		kept in the project directory.
```
