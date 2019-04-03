#!/usr/bin/env bash

# This script builds the smallest image possible with a small dataset

APP_NAME="bus-service"
AUTHOR="YOUR NAME"

#
# build the app and statically link all dependencies
#
CGO_ENABLED=0 GOOS=linux go build -a -ldflags '-extldflags "-static"' bus.go

#
# build the container from scratch
#
newcontainer=$(buildah from scratch)

scratchmnt=$(buildah mount $newcontainer)
mkdir -p $scratchmnt/data
cp bus $scratchmnt
cp data/busses.json $scratchmnt/data

buildah config --entrypoint '["/bus"]' --port 8080 --user 1000 $newcontainer
buildah config --author "$AUTHOR" --label name="$APP_NAME" $newcontainer

buildah commit $newcontainer bus-service

buildah unmount $newcontainer
buildah rm $newcontainer

