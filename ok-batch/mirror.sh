#!/bin/bash
#
cd /var/www/ok-batch/run/
exec wget -nv --mirror --no-parent \
  "http://files.source.com:89/.NET/The%20Source%20.NET%202011.1/"

