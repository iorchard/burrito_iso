#!/bin/bash
mkdir -p output
podman build -t docker.io/jijisa/burrito-isobuilder .
podman run --privileged -v $(pwd)/output:/output --rm docker.io/jijisa/burrito-isobuilder
