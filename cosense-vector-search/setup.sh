#!/usr/bin/env bash
# setup script for Debian-like systems

IMAGE='docker.io/library/solr:9.8.0-slim@sha256:fd236ed14ace4718c99d007d7c0360307ecba380ac4927abdf91fbf105804f28'

sudo apt-get update
sudo apt-get install -y podman
podman pull "$IMAGE"

sudo mkdir /var/solr
sudo chown 8983:8983 -R /var/solr

podman run \
  --name cosense-vector-search \
  --publish 127.0.0.1:8983:8983 \
  --volume /var/solr:/var/solr \
  "$IMAGE" -c
