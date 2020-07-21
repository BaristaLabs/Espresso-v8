V8_VERSION ?= 8.4.371.19

build-aarch64:
	docker build -f ./Dockerfile.aarch64 -t baristalabs/espresso-v8-aarch64:${V8_VERSION} --build-arg V8_VERSION=${V8_VERSION} -m 4g .
	docker create -ti --name dummy baristalabs/espresso-v8-aarch64:${V8_VERSION} bash
	docker cp dummy:/path/to/file /dest/to/file
	docker rm -f dummy