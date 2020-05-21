#!/bin/bash

if [ -z "$REPO_ROOT_DIR" ]; then echo 'you have to `source .envrc` in project root dir or consider installing https://direnv.net' ; exit 255 ; fi
trap "set +x" INT TERM QUIT EXIT

IPs=$(gcloud compute instances list | tail -n +2 | awk '{printf "%s %s\n", $4, $5}')
ipPattern='[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}'

while IFS= read -r line ; do 
    internalIP=${line% *}
    externalIP=${line#* }
    # echo "$internalIP $externalIP"

    if [[ $externalIP =~ $ipPattern ]]; then
        # is an ip
        echo "ssh-keygen -R $externalIP"
        ssh-keygen -R $externalIP
    elif [[ $internalIP =~ $ipPattern ]]; then
        # is an ip
        echo ssh-keygen -R $internalIP
        ssh-keygen -R $internalIP
    fi
    
done <<< "$IPs"

