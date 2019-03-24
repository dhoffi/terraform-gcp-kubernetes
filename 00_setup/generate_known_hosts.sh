#!/bin/bash

if [ -z "$REPO_ROOT_DIR" ]; then
    echo 'you have to `source .envrc` in project root dir or consider installing https://direnv.net'
    exit -1
fi

jumpbox="$TF_VAR_JUMPBOXIP"

>&2 echo "retrieving master ips..."
masterIps=$(gcloud compute instances list --format=json | jq -r --arg NODETYPE master --arg DEST $DEST --arg WORKSPACE $(cat $REPO_ROOT_DIR/.terraform/environment) '.[] | select((.labels.node == $NODETYPE) and (.labels.dest == $DEST) and (.labels.env == $WORKSPACE)) | .networkInterfaces[].networkIP')

>&2 echo "retrieving worker ips..."
workerIps=$(gcloud compute instances list --format=json | jq -r --arg NODETYPE worker --arg DEST $DEST --arg WORKSPACE $(cat $REPO_ROOT_DIR/.terraform/environment) '.[] | select((.labels.node == $NODETYPE) and (.labels.dest == $DEST) and (.labels.env == $WORKSPACE)) | .networkInterfaces[].networkIP')

result+=('')
for ip in $masterIps; do
  >&2 echo "ssh-keyscan $ip (on jumpbox $jumpbox)"
  # add -H option to generated Hashed fingerprints
  khline=$(ssh -i $TF_VAR_JUMPBOXSSHFILE $TF_VAR_JUMPBOXUSER@$jumpbox -- "ssh-keyscan -t ecdsa $ip")
  result+=("$khline")
done
for ip in $workerIps; do
  >&2 echo "ssh-keyscan $ip (on jumpbox $jumpbox)"
  # add -H option to generated Hashed fingerprints
  khline=$(ssh -i $TF_VAR_JUMPBOXSSHFILE $TF_VAR_JUMPBOXUSER@$jumpbox -- "ssh-keyscan -t ecdsa $ip")
  result+=("$khline")
done

echo ''
echo 'copy&pastable cmd for - either local (excluding ssh EOT lines) - or on jumpbox (with ssh EOT lines):'
echo ''
echo "ssh -i $TF_VAR_JUMPBOXSSHFILE $TF_VAR_JUMPBOXUSER@$jumpbox /bin/bash << EOT"
echo "echo '# myk8spray' >> ~/.ssh/known_hosts"
for khline in "${result[@]}"; do
  if [ ! -z "$khline" ]; then
    echo "echo '$khline' >> ~/.ssh/known_hosts"
  fi
done
echo 'chmod 600 ~/.ssh/known_hosts'
echo 'EOT'

echo ''
echo ''
echo 'plain text for copy and paste into local and/or jumpboxs ~/.ssh/known_hosts:'
echo "# myk8spray"
printf '%s\n' "${result[@]}"
