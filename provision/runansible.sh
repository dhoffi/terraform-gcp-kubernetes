#!/bin/bash

time ANSIBLE_FORCE_COLOR=true ansible-playbook -v -i inventory/cluster-hoffi1/hosts.ini --become --become-user=root cluster.yml 2>&1 | tee ansibleOutput.log | sed -E 's/(\\n|\\r)/\n/g'
