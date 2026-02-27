#!/bin/bash

set -e

case "$1" in
"build")
	python update.py

	PLATFORMS="linux/amd64,linux/arm64"

	# ensure buildx builder with multi-platform support exists
	docker buildx inspect multiarch > /dev/null 2>&1 || \
		docker buildx create --name multiarch --driver docker-container --use
	docker buildx use multiarch

	# docker buildx build (multi-platform)
	find . -maxdepth 1 -type d -name '0.*' -exec sh -c \
		'docker buildx build --platform '"${PLATFORMS}"' -t wiktorn/overpass-api:$(basename "$1") -f "$1"/Dockerfile . --push' sh {} \;

	# tag latest using imagetools
	LATEST_VERSION=$(find . -maxdepth 1 -type d -regex '\./[0-9]\.[0-9]\.[0-9]*' -print0 | sort -nz | tail -z -n 1 | xargs basename)
	if [ -n "$LATEST_VERSION" ]; then
		docker buildx imagetools create -t wiktorn/overpass-api:latest "wiktorn/overpass-api:${LATEST_VERSION}"
	fi
	;;
"push")
	# docker push
	find . -maxdepth 1 -type d -name '0.*' -exec sh -c 'docker push "wiktorn/overpass-api:$(basename "$1")"' sh {} \;
	docker push wiktorn/overpass-api:latest
	;;
"$1")
	echo "Invalid argument $1"
	echo "Valid arguments:"
	echo "$0 build - to build docker images"
	echo "$0 push - to push built images to docker hub"
	exit 1
	;;
esac
