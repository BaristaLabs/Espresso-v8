V8_VERSION ?= 8.4.371.19
V8_TARGET ?= v8_monolith # d8...

TARGET_PLATFORM ?= linux #linux - for macOS use pwsh
TARGET_ARCH ?= aarch64 #x86, x64, armv7hf, aarch64...

BASE_IMAGE ?= "balenalib/aarch64-ubuntu:bionic" # ubuntu:bionic, balenalib/armv7hf-ubuntu:bionic, balenalib/aarch64-ubuntu:bionic, 
IMAGE_PREFIX ?= baristalabs/espresso-v8
IMAGE_TARGET_NAME ?= monolith

default: help

help:
	@echo 'Builds V8 $(V8_VERSION) binaries for embedding'
	@echo
	@echo 'Usage:'
	@echo '    make build    Build ARM64 based binaries
	@echo '    make push     Push ARM64 based binaries
	@echo '    make publish  Publish ARM64 based nuget packages
	@echo

build:
	docker build -f ./Dockerfile.linux -t $(IMAGE_PREFIX)-$(IMAGE_TARGET_NAME)-$(TARGET_ARCH):$(V8_VERSION) --build-arg BASE_IMAGE=$(BASE_IMAGE) --build-arg V8_ARCH=$(TARGET_ARCH) --build-arg V8_VERSION=$(V8_VERSION) --build-arg V8_TARGET=$(V8_TARGET) --build-arg TARGETPLATFORM=$(TARGET_PLATFORM)/$(TARGET_ARCH) .

push:
	docker push $(IMAGE_PREFIX)-$(IMAGE_TARGET_NAME)-$(TARGET_ARCH):$(V8_VERSION)
	docker tag $(IMAGE_PREFIX)-$(IMAGE_TARGET_NAME)-$(TARGET_ARCH):$(V8_VERSION) docker.io/$(IMAGE_PREFIX)-$(IMAGE_TARGET_NAME)-$(TARGET_ARCH):latest
	docker push docker.io/$(IMAGE_PREFIX)-$(IMAGE_TARGET_NAME)-$(TARGET_ARCH):latest

publish:
	docker create -ti --name dummy $(IMAGE_PREFIX)-monolith-aarch64:$(V8_VERSION) bash
	docker cp dummy:/build/v8/out/v8.release/ ./bin/$(TARGET_ARCH)/
	docker cp dummy:/build/v8/include/ ./bin/$(TARGET_ARCH)/
	docker rm -f dummy

.PHONY: help build push publish