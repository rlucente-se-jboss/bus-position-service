#!/usr/bin/env bash

QUAY_USER="YOUR QUAY USER NAME"
QUAY_PASS="YOUR QUAY PASSWORD"
APP_NAME="bus-service"
AUTHOR="YOUR NAME"

#
# build the go app
#
go build bus.go

#
# identify all dependencies for bash
#
echo bash.x86_64 > pending-list.txt

rm -f resolved-list.txt
touch resolved-list.txt

while [[ "$(wc -l pending-list.txt | awk '{print $1}')" -gt 0 ]]
do
    # for each package in pending-list, find all dependencies
    cat pending-list.txt | xargs yum deplist | grep provider | \
        grep 'x86_64\|noarch' | awk '{print $2}' | \
        sort -u > tmplist.txt

    # uniquely merge dependencies in both pending-list and resolved-list
    cat pending-list.txt resolved-list.txt | sort -u > tmp.txt
    mv tmp.txt resolved-list.txt

    # get remaining new dependencies from depllist search
    mv tmplist.txt pending-list.txt

    # remove all new dependencies that are already in resolved-list
    comm -23 pending-list.txt resolved-list.txt > tmplist.txt
    mv tmplist.txt pending-list.txt
done

rm pending-list.txt

#
# build the container
#
newcontainer=$(buildah from scratch)
buildah copy $newcontainer bus 40min_busses.json /
scratchmnt=$(buildah mount $newcontainer)
rpm --root $scratchmnt --initdb
rm -fr /tmp/*.rpm
cat resolved-list.txt | xargs yumdownloader --destdir=/tmp
yum install --installroot $scratchmnt --releasever=7 \
  --setopt=install_weak_deps=false --setopt=tsflags=nodocs \
  --setopt=override_install_langs=en_US.utf8 -y /tmp/*.rpm
yum clean all -y --installroot $scratchmnt --releasever=7
rm -rf $scratchmnt/var/cache/yum
buildah config --entrypoint /bus $newcontainer
buildah config --author "$AUTHOR" --created-by "$QUAY_USER" \
    --label name="$APP_NAME" $newcontainer
buildah commit $newcontainer bus-service
buildah unmount $newcontainer
buildah rm $newcontainer

# make sure to login first
podman logout quay.io
podman login quay.io -u "$QUAY_USER" -p "$QUAY_PASS"
buildah push "$APP_NAME" docker://quay.io/$QUAY_USER/$APP_NAME

