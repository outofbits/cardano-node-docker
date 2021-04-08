#!/bin/bash
if [ -z $1 ]; then
    echo "error: the cardano-node version is not specified (from which the image shall be built)"
    echo "usage: $0 <cardano-node-version>"
    exit 1
fi

DFILE_VERSION=1.7

docker build --build-arg NODE_VERSION=$1 \
           --build-arg NODE_BRANCH="master" \
           -t "adalove/cardano-node:$1" .
