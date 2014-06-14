all: travis-run.1

travis-run.1:
	help2man --version-string=0.1 -s 1 -N ./travis-run > travis-run.1 -n "Run travis-ci builds locally using Docker"

install:
	DESTDIR=$(DESTDIR) sh -x ./install.sh
