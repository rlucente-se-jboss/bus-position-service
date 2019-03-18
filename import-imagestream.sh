#!/usr/bin/env bash

set -x

APP=bus-service
PROJECT=openshift

oc logout

eval $(minishift docker-env)
IMAGEID=$(docker load -i $APP\@latest.tar.gz | grep sha256 | awk '{print $4}')

oc login -u admin -p admin
docker login -u admin -p $(oc whoami -t) 172.30.1.1:5000
docker tag $IMAGEID 172.30.1.1:5000/$PROJECT/$APP
docker push 172.30.1.1:5000/$PROJECT/$APP
oc logout

