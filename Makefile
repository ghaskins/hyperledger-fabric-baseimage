NAME ?= hyperledger/fabric-baseimage-sandbox
VERSION=$(shell cat ./release)
ARCH=$(shell uname -m)
DOCKER_TAG ?= $(ARCH)-$(VERSION)
VAGRANTIMAGE=packer_virtualbox-iso_virtualbox.box

DOCKER_BASE_x86_64=ubuntu:trusty
DOCKER_BASE_s390x=s390x/ubuntu:xenial
DOCKER_BASE_ppc64le=ppc64le/ubuntu:xenial

DOCKER_BASE=$(DOCKER_BASE_$(ARCH))

ifeq ($(DOCKER_BASE), )
$(error "Architecture \"$(ARCH)\" is unsupported")
endif

all: vagrant docker

$(VAGRANTIMAGE): packer.json
	ATLAS_ARTIFACT=$(NAME) \
	BASEIMAGE_RELEASE=$(VERSION) \
	packer build -only virtualbox-iso packer.json

Dockerfile: Dockerfile.in Makefile
	@echo "# Generated from Dockerfile.in.  DO NOT EDIT!" > $@
	@cat Dockerfile.in | \
	sed -e  "s|_DOCKER_BASE_|$(DOCKER_BASE)|" >> $@

docker: Dockerfile release
	@echo "Generating docker"
	@docker build -t $(NAME):$(DOCKER_TAG) .
	@docker login \
		--email=$(DOCKER_HUB_EMAIL) \
		--username=$(DOCKER_HUB_USERNAME) \
		--password=$(DOCKER_HUB_PASSWORD)
	@docker push $(NAME):$(DOCKER_TAG)

vagrant: $(VAGRANTIMAGE) remove release
	vagrant box add -name $(NAME) $(VAGRANTIMAGE)

remove:
	-vagrant box remove --box-version 0 $(NAME)

clean: remove
	-rm $(VAGRANTIMAGE)
	-rm Dockerfile
