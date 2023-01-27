#!/bin/bash

podman build -t docker.io/jijisa/burrito-isobuilder .
podman run -v output:/output --rm docker.io/jijisa/burrito-isobuilder
