SHELL := /usr/bin/env bash -o pipefail

# This controls the location of the cache.
PROJECT := gobufghactionsexample
# This controls the remote SSH git location to compare against for breaking changes.
# See https://buf.build/docs/inputs#ssh for more details.
SSH_GIT := ssh://git@github.com/andream16/gobufghactionsexample.git
# This controls the version of buf to install and use.
BUF_VERSION := 0.25.0
# This controls the version of protoc to install and use.
PROTOC_VERSION := 3.7.1
# Protoc zip name used for installing protoc
PROTOC_ZIP=protoc-3.7.1-linux-x86_64.zip
# Directory with protos
PROTO_DIR := contracts/proto
# Directory with generated code
GEN_OUT_DIR := contracts/build/go

### Everything below this line is meant to be static, i.e. only adjust the above variables. ###

UNAME_OS := $(shell uname -s)
UNAME_ARCH := $(shell uname -m)
# Buf will be cached to ~/.cache/buf-example.
CACHE_BASE := $(HOME)/.cache/$(PROJECT)/contracts
# This allows switching between i.e a Docker container and your local setup without overwriting.
CACHE := $(CACHE_BASE)/$(UNAME_OS)/$(UNAME_ARCH)
# The location where buf will be installed.
CACHE_BIN := $(CACHE)/bin
# Marker files are put into this directory to denote the current version of binaries that are installed.
CACHE_VERSIONS := $(CACHE)/versions
# List of proto files
PROTO_FILES=$(shell find $(PROTO_DIR) -type f -name '*.proto')

# Update the $PATH so we can use buf directly
export PATH := $(abspath $(CACHE_BIN)):$(PATH)
# Update GOBIN to point to CACHE_BIN for source installations
export GOBIN := $(abspath $(CACHE_BIN))
# This is needed to allow versions to be added to Golang modules with go get
export GO111MODULE := on

# BUF points to the marker file for the installed version.
BUF := $(CACHE_VERSIONS)/buf/$(BUF_VERSION)
$(BUF):
	@echo Installing Buf
	@rm -f $(CACHE_BIN)/buf
	@mkdir -p $(CACHE_BIN)
	@curl -sSL \
		"https://github.com/bufbuild/buf/releases/download/v$(BUF_VERSION)/buf-$(UNAME_OS)-$(UNAME_ARCH)" \
		-o "$(CACHE_BIN)/buf"
	@chmod +x "$(CACHE_BIN)/buf"

# PROTOC points to the marker file for the installed version.
PROTOC := $(CACHE_VERSIONS)/protoc/$(PROTOC_VERSION)
$(PROTOC):
	@echo Installing Protoc
	@rm -rf $(CACHE_BIN)/protoc
	@mkdir -p $(CACHE_BIN)
	@curl -OL \
		https://github.com/protocolbuffers/protobuf/releases/download/v$(PROTOC_VERSION)/$(PROTOC_ZIP)
	@unzip -o $(PROTOC_ZIP) -d . bin/protoc
	@mv bin/protoc $(CACHE_BIN)
	@rm -rf $(PROTOC_ZIP) bin
	@chmod +xw "$(CACHE_BIN)/protoc"
	@export GO111MODULE=on
	@go get github.com/golang/protobuf/protoc-gen-go \
		google.golang.org/grpc/cmd/protoc-gen-go-grpc
	@export PATH="$PATH:$(go env GOPATH)/bin"

.DEFAULT_GOAL := local

# local is meant to be used locally
.PHONY: local
local: $(BUF) $(PROTOC_GEN_GO)
	@make clean
	@make lint
	@make breaking
	@make gen

# lint runs the buf linter
.PHONY: lint
lint:
	@buf check lint

# breaking checks for breaking changes against main
.PHONY: breaking
breaking:
	@buf check breaking --against-input "$(SSH_GIT)#branch=main"

# gen generates go stubs from protos
.PHONY: gen
gen:
	@rm -rf $(GEN_OUT_DIR)
	@mkdir -p $(GEN_OUT_DIR)
	@protoc --proto_path=$(PROTO_DIR) --go_out=plugins=grpc:$(GEN_OUT_DIR) --go_opt=paths=source_relative $(PROTO_FILES)

# clean deletes any files not checked in and the cache for all platforms.
.PHONY: clean
clean:
	@git clean -xdf
	@rm -rf $(CACHE_BASE)