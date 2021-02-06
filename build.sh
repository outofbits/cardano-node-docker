#!/bin/bash
DFILE_VERSION=1.6

docker build --build-arg NODE_VERSION=$1 \
           --build-arg NODE_REPOSITORY="https://github.com/input-output-hk/cardano-node" \
           --build-arg NODE_BRANCH="master" \
           -t "adalove/cardano-node:$DFILE_VERSION-node$1" .
