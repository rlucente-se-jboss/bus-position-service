#!/usr/bin/env bash

# This builds a more canonical image with the ability to copy files
# to the mounted data volume

APP_NAME="bus-service"
AUTHOR="YOUR NAME"

#
# build the app (not statically linked since we get glibc from the
# tar installation)
#
go build bus.go

#
# the --resolve argument on yumdownloader doesn't seem to want to
# pull down all the transitive dependencies, so we'll do it quickly
# in a loop.  The only packages we need are:
#
# tar -  enables 'oc cp' to copy data into a container mounted
#        volume
#
# identify all dependencies for bash and tar
# 
echo tar.x86_64 > pending-list.txt
truncate -s 0 resolved-list.txt

# repeat while still pending dependencies
while [[ -s pending-list.txt ]]
do
    # for each package in pending-list, find all dependent packages
    # (limited to x86_64 and noarch)
    cat pending-list.txt | xargs yum deplist | grep provider | \
        grep 'x86_64\|noarch' | awk '{print $2}' | \
        sort -u > tmplist.txt

    # since we've just determined the dependencies in pending-list,
    # uniquely merge dependencies in both pending-list and resolved-list
    cat pending-list.txt resolved-list.txt | sort -u > tmp.txt
    mv tmp.txt resolved-list.txt

    # get remaining new dependencies from deplist search
    mv tmplist.txt pending-list.txt

    # remove all new dependencies that are already in resolved-list
    comm -23 pending-list.txt resolved-list.txt > tmplist.txt
    mv tmplist.txt pending-list.txt
done

rm pending-list.txt

#
# build the container from scratch
#
newcontainer=$(buildah from scratch)

scratchmnt=$(buildah mount $newcontainer)
mkdir -p $scratchmnt/data
cp bus $scratchmnt
cp data/busses.json $scratchmnt/data

# only installing bash and tar (and their dependencies)
rpm --root $scratchmnt --initdb
rm -fr /tmp/*.rpm
cat resolved-list.txt | xargs yumdownloader --destdir=/tmp
yum install --installroot $scratchmnt --releasever=7 \
  --setopt=install_weak_deps=false --setopt=tsflags=nodocs \
  --setopt=override_install_langs=en_US.utf8 -y /tmp/*.rpm

yum clean all -y --installroot $scratchmnt --releasever=7
rm -rf $scratchmnt/var/cache/yum

buildah config --entrypoint '["/bus"]' --port 8080 --user 1000 $newcontainer
buildah config --author "$AUTHOR" --label name="$APP_NAME" $newcontainer

buildah commit $newcontainer bus-service

buildah unmount $newcontainer
buildah rm $newcontainer

