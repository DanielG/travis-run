VERSION=$(shell git describe)

all: README.md travis-run.1

travis-run.1: travis-run
	help2man --version-string=0.1 -s 1 -N ./travis-run > travis-run.1 -n "Run travis-ci builds locally using Docker"

README.md: travis-run.1 README.md.in
	cat README.md.in > README.md
	echo '```' >> README.md
	MANWIDTH=80 man ./travis-run.1 >> README.md
	echo '```' >> README.md

clean:
	rm -f README.md travis-run.1

install:
	DESTDIR=$(DESTDIR) sh -x ./install.sh $(VERSION)

images: $(wildcard docker/* vm/* keys/travis-run_id_rsa script/*)
	sh docker-build-images.sh

push:
	docker login
	docker push dxld/travis-run:script_v0.2
	docker push dxld/travis-run:haskell_v0.2
	docker push dxld/travis-run:base_v0.2
