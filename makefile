TAG := lts-ubuntu-12.26-v6
IMAGE := dragonflyscience/dragonfly-website:$(TAG)

HS := $(shell find haskell/WebSite -name *.hs)

RUN ?=
RUN_WEB ?=
CI ?=
DOCKER_CACHE ?= $$HOME/docker-cache
WEPACK_CACHE ?= $(DOCKER_CACHE)/webpack-cache
WEBPACK_CONTAINER_CACHE ?= /root/webpack

# Process args, to build up the docker command
ifneq ($(CI), true)
RUN = docker-compose --profile build run --rm npm
RUN_WEB = docker-compose --profile build run --publish 3000:3000 --rm website
endif

all: .env install build

.env:
ifneq ($(CI), true)
	echo IMAGE=$(IMAGE) >> .env
	echo DOCKER_CACHE=$(DOCKER_CACHE) >> .env
	echo WEPACK_CACHE=$(WEPACK_CACHE) >> .env
	echo WEBPACK_CONTAINER_CACHE=$(WEBPACK_CONTAINER_CACHE) >> .env
endif

# (cd front-end && npm watch) &
up: .env install
	mkdir -p _site/assets
	docker-compose up --remove-orphans

develop: up

down:
	docker-compose down
	docker volume rm dragonfly-website_nfsmount

docker:
	docker build --tag $(IMAGE) .

pull:
	docker pull $(IMAGE)

push:
	docker push $(IMAGE)

# NPM Commands
install:
	$(RUN) bash -c "cd /work/front-end && npm install"

build-npm: build-website
	$(RUN) bash -c 'cd front-end && npm i && npm run build'

static:
	$(RUN_WEB) bash -c 'cd front-end && npm run staging'

# Build commands
website: $(HS) haskell/Site.hs
	$(RUN_WEB) bash -c 'cd haskell && \
		stack build && \
		cp $$(stack path --local-install-root)/bin/website ../website'

build-website: website
	$(RUN_WEB) bash -c 'cd ./content && ../website build'
	touch $@

.PHONY: build
build: build-website build-npm

# Utility commands
clean:
	rm -rf website _site .cache .env \
				content/fonts/*.css \
				build-website

compress:
	$(RUN) bash -c 'tar -czf static-site.tgz _site/*'
