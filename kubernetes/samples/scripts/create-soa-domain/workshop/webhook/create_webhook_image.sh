#!/bin/bash
IMAGE=$1
if [ -z $IMAGE ]; then
  IMAGE=webhook:1.0
fi
docker rmi $IMAGE
docker build -t $IMAGE -f Dockerfile . --build-arg http_proxy=$http_proxy --build-arg https_proxy=$https_proxy --build-arg no_proxy=$no_proxy
