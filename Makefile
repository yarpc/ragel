.DEFAULT_GOAL := release

UNAME_OS := $(shell uname -s)
UNAME_ARCH := $(shell uname -m)

BUILD_BASE := /tmp/ragel-build

BUILD := $(BUILD_BASE)/$(UNAME_OS)/$(UNAME_ARCH)

LIB := $(BUILD)/lib
BIN := $(BUILD)/bin

RELEASE := $(shell pwd)/release

RAGEL_VERSION := 6.10

RAGEL_LIB = $(LIB)/ragel-$(RAGEL_VERSION)
RAGEL_TAR = $(RAGEL_LIB)/ragel.tar.gz
RAGEL = $(BIN)/ragel

$(RAGEL_TAR):
	@mkdir -p $(RAGEL_LIB)
	curl -L "https://www.colm.net/files/ragel/ragel-$(RAGEL_VERSION).tar.gz" > $(RAGEL_TAR)

$(RAGEL): $(RAGEL_TAR)
	@mkdir -p $(BIN)
	cd $(RAGEL_LIB); tar xzf $(RAGEL_TAR)
	cd $(RAGEL_LIB)/ragel-$(RAGEL_VERSION); ./configure --prefix=$(RAGEL_LIB) --disable-manual --disable-dependency-tracking
	cd $(RAGEL_LIB)/ragel-$(RAGEL_VERSION); make install
	cp $(RAGEL_LIB)/bin/ragel $(RAGEL)

DOCKER_VERSION := 17.03.1-ce
DOCKER_OS := $(UNAME_OS)
DOCKER_ARCH := $(UNAME_ARCH)

DOCKER_LIB := $(LIB)/docker-$(DOCKER_VERSION)
DOCKER_TAR := $(DOCKER_LIB)/docker.tar.gz
DOCKER := $(BIN)/docker

$(DOCKER_TAR):
	@mkdir -p $(DOCKER_LIB)
	curl -L "https://get.docker.com/builds/$(DOCKER_OS)/$(DOCKER_ARCH)/docker-$(DOCKER_VERSION).tgz" > $(DOCKER_TAR)

$(DOCKER): $(DOCKER_TAR)
	@mkdir -p $(BIN)
	cd $(DOCKER_LIB); tar xzf $(DOCKER_TAR)
	cp $(DOCKER_LIB)/docker/docker $(DOCKER)

DOCKERFILE := Dockerfile
DOCKER_IMAGE := uber/ragel:$(RAGEL_VERSION)

ifdef DOCKER_HOST
DOCKER_BUILD_FLAGS ?= --compress
endif

DOCKER_RUN_FLAGS := -v $(shell pwd):/app -v $(BUILD_BASE):$(BUILD_BASE)

.PHONY: clean
clean:
	rm -rf $(BUILD_BASE) $(RELEASE)

.PHONY: local-build
local-build: $(RAGEL)

.PHONY: docker-build
docker-build: $(DOCKER)
	PATH=$$PATH:$(BIN) docker build $(DOCKER_BUILD_FLAGS) -t $(DOCKER_IMAGE) -f $(DOCKERFILE) .
	PATH=$$PATH:$(BIN) docker run $(DOCKER_RUN_FLAGS) $(DOCKER_IMAGE) make local-build

.PHONY: build
build: __check_darwin local-build docker-build

.PHONY: release
release: build
	@rm -rf $(RELEASE)
	@mkdir -p $(RELEASE)
	cp $(BUILD_BASE)/Darwin/x86_64/bin/ragel $(RELEASE)/ragel-Darwin-x86_64
	cp $(BUILD_BASE)/Linux/x86_64/bin/ragel $(RELEASE)/ragel-Linux-x86_64

.PHONY: __check_darwin
__check_darwin:
ifneq ($(UNAME_OS),Darwin)
	$(error You must run the build from a Darwin machine, uname -s returned $(UNAME_OS))
else
	@echo
endif
