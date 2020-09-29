#!/bin/bash

# -e: end execution on error
# -u: error on undefined variable
# -o pipefail: error if any part of a pipe fails
set -e -u -o pipefail

apt-get update
apt-get install --yes --no-install-recommends \
    wget bzip2 ca-certificates
apt-get clean
rm -rf /var/lib/apt/lists/*

# Self-destruct
rm $0
