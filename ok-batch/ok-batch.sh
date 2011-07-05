#!/bin/bash

# Just add jobs here...
JOBS="mirror"

for J in $JOBS; do
  curl --silent \
    'http://localhost/ok-batch.cgi?action=autorun&job='$J \
    >/dev/null
done
