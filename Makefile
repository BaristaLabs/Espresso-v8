# V8 Version Number
V8_VERSION ?= 8.4.371.19
# V8 Build Target - v8_monolith, d8, etc... gn --list targets will show the list
V8_TARGET ?= v8_monolith

# Target Platform - for Windows, ensure Docker is in windows container mode. For macOS, the powershell build scripts is the only way, sadly.
TARGET_PLATFORM ?= linux
# Target CPU Architecture - #x86, x64, armv7hf, aarch64...
TARGET_ARCH ?= aarch64

# The desired based image - ubuntu:bionic, balenalib/armv7hf-ubuntu:bionic, balenalib/aarch64-ubuntu:bionic, 
BASE_IMAGE ?= "balenalib/aarch64-ubuntu:bionic"

IMAGE_PREFIX ?= baristalabs/espresso-v8
IMAGE_ARCH_NAME ?= aarch64
IMAGE_DISTRO ?= ubuntu
IMAGE_TARGET_NAME ?= monolith


# Taken together the image name is baristalabs/espresso-v8-<IMAGE_ARCH_NAME>-<IMAGE_DISTRO>-<IMAGE_TARGET_NAME>:<V8_VERSION>

default: help

help:
	@echo 'Builds V8 $(V8_VERSION) binaries for embedding'
	@echo
	@echo 'Usage:'
	@echo '    make build    Creates a docker image which has V8 built for ARM64 ubuntu monolith
	@echo '    make push     Push the above image
	@echo '    make publish  From the built image, extracts the V8 binaries and headers and packages and publishes corresponding NuGet packages.
	@echo

build:
	docker build -f ./Dockerfile.linux -t $(IMAGE_PREFIX)-$(IMAGE_ARCH_NAME)-$(IMAGE_DISTRO)-$(IMAGE_TARGET_NAME):$(V8_VERSION) --build-arg BASE_IMAGE=$(BASE_IMAGE) --build-arg V8_ARCH=$(TARGET_ARCH) --build-arg V8_VERSION=$(V8_VERSION) --build-arg V8_TARGET=$(V8_TARGET) --build-arg TARGETPLATFORM=$(TARGET_PLATFORM)/$(TARGET_ARCH) .

push:
	docker push $(IMAGE_PREFIX)-$(IMAGE_ARCH_NAME)-$(IMAGE_DISTRO)-$(IMAGE_TARGET_NAME):$(V8_VERSION)
	docker tag $(IMAGE_PREFIX)-$(IMAGE_ARCH_NAME)-$(IMAGE_DISTRO)-$(IMAGE_TARGET_NAME):$(V8_VERSION) docker.io/$(IMAGE_PREFIX)-$(IMAGE_ARCH_NAME)-$(IMAGE_DISTRO)-$(IMAGE_TARGET_NAME):latest
	docker push docker.io/$(IMAGE_PREFIX)-$(IMAGE_ARCH_NAME)-$(IMAGE_DISTRO)-$(IMAGE_TARGET_NAME):latest

publish:
	docker create -ti --name dummy $(IMAGE_PREFIX)-monolith-aarch64:$(V8_VERSION) bash
	docker cp dummy:/build/v8/out/v8.release/ ./bin/$(TARGET_ARCH)/
	docker cp dummy:/build/v8/include/ ./bin/$(TARGET_ARCH)/
	docker rm -f dummy

.PHONY: help build push publish