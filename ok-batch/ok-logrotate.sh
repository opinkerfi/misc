#!/bin/bash

# Add jobs here
JOBS="mirror"

cd /var/www/ok-batch/run
for J in $JOBS; do
  NL=$J.$(date +%Y-%m --date yesterday).log
  mv $J.log $NL
  gzip $NL
done
