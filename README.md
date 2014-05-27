travis-run
==========

Run *travis-ci* build locally with *schroot* or *Vagrant*+*Docker*.

Installation
============

For now you should just clone https://github.com/DanielG/travis-run.git, run
`bundle install` in there and add the directory to your *PATH*.

Usage
=====

- Create a virtual machine: `travis-run create`

  With the `vagrant` backend this involves doing a `docker build` inside the
  Host VM or on the system running `travis-run-create` (with Linux).

- Run your builds locally: `travis-run`

  This will spin up the Vagrant Host VM if needed, create a new docker
  container, copy the build directory into the container and execute the build
  as it would be on travis-ci.

  _Note_ that unlike travis-ci *travis-run* doesn't do a clean `git checkout`
  but rather just copies the contents of the current directory as is. This might
  lead to the build failing because the build directory is unclean, however this
  is still desirable as it allows us to do a build without committing
  changes. To avoid this you should run a `clean` action before anything else in
  the *script* section of your `.travis.yml`.


```
Usage: ./travis-run [OPTIONS..] [BACKEND_OPTIONS..] [COMMAND [ARGS..]]
Global Options (OPTIONS):
	-b, --backend=BACKEND
		Virtualization backend to use. Currently avalialbe backends:
		  schroot, vagrant
		(defaults to: vagrant)
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

		Backend Options for `schroot':
			--schrot-user=USER
				Name of the user to run commands inside the
				chroot as, see -u option of the `schroot'
				command.


	stop
		Stop running build VM. This will tear down the VM as well as
		all it's disk state.


	create
		Setup build VM. Depending on the backend it might be stored
		globally or in `.travis-run' in the current directory.
		Backend Options for `schroot':
			--schrot-user=USER
				Name of the user outside the schroot that will
				run `travis-run'. This is needed for file
				sync to work. (required)
		Backend Options for `vagrant':
			--vagrant-docker-from=BASE_IMAGE
				Docker image to use as the base for the
				container, see `FROM' Dockerfile command.
				(defaults to: ubuntu:presice)


	clean
		Stop running build VM, and clean any backend specific state
		kept in the project directory.
```
