#!/usr/bin/env bash

set -x

QUAY_USER="YOUR QUAY USER NAME"
QUAY_PASS="YOUR QUAY PASSWORD"
APP_NAME="bus-service"
AUTHOR="YOUR NAME"

# make app as statically linked as possible
CGO_ENABLED=0 GOOS=linux go build -a -ldflags '-extldflags "-static"' bus.go

newcontainer=$(buildah from scratch)
buildah copy $newcontainer bus 40min_busses.json /
buildah config --entrypoint /bus $newcontainer
buildah config --author "$AUTHOR" --created-by "$QUAY_USER" --label name="$APP_NAME" $newcontainer
buildah commit $newcontainer bus-service

# make sure to login first
podman login quay.io -u "$QUAY_USER" -p "$QUAY_PASS"
buildah push "$APP_NAME" docker://quay.io/$QUAY_USER/$APP_NAME

