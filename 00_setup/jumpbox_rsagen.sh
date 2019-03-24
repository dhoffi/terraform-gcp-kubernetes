#!/bin/bash

if [ -z "$REPO_ROOT_DIR" ]; then echo 'you have to `source .envrc` in project root dir or consider installing https://direnv.net' ; exit -1 ; fi
trap "set +x" INT TERM QUIT EXIT

username=$TF_VAR_JUMPBOXUSER
filepath=$TF_VAR_JUMPBOXSSHFILE

if [ ! -s "$filepath" ]; then
    set -x
    ssh-keygen -t rsa -b 4096 -C "$username" -N '' -f $filepath
fi
