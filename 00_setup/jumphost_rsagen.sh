#!/bin/bash

if [ -z "$REPO_ROOT_DIR" ]; then echo 'you have to `source .envrc` in project root dir or consider installing https://direnv.net' ; fi
trap "set +x" INT TERM QUIT EXIT

set -x
ssh-keygen -t rsa -b 4096 -C 'gcpadmin' -N '' -f ~/.ssh/gcp_jumphost

