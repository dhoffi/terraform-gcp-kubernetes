#!/bin/bash

if [ -z "$REPO_ROOT_DIR" ]; then
    echo 'you have to `source .envrc` in project root dir or consider installing https://direnv.net'
    exit -1
fi

ANSIBLE_FORCE_COLOR=true ansible-playbook -v --limit="all" --inventory-file=$REPO_ROOT_DIR/provision/inventories/dev/dev-inventory.ini ansible_hello_world.yml | sed 's/\\n/\n/g'