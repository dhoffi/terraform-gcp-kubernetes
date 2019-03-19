#!/bin/bash

time ANSIBLE_FORCE_COLOR=true ansible-playbook -v -i inventory/cluster-hoffi1/hosts.ini --become --become-user=root cluster.yml | sed -E 's/(\\n|\\r)/\n/g'
