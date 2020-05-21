#!/bin/bash

if [ -z "$REPO_ROOT_DIR" ]; then echo 'you have to `source .envrc` in project root dir or consider installing https://direnv.net' ; exit 255 ; fi
trap "set +x" INT TERM QUIT EXIT

function usage() { echo "usage: $0 [-f <oldIp>] <newIp>"; exit 255 ; }

ipPattern='[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}'
forceOldIP="false"
if [ "$1" = "-f" ]; then
  forceOldIP="true"
  if [ -z "$2" ] || [ ! -z "$(echo $2 | sed -E s/$ipPattern//)" ]; then usage ; fi
  oldIP=$2
  shift 2
fi
newIP="$1"

if [ -z "$newIP" ]; then
  echo "determining new jumphost ip ..."
  newIP=$(gcloud compute instances list --format=json | jq -r --arg DEST $DEST --arg WORKSPACE $(cat $REPO_ROOT_DIR/.terraform/environment) '.[] | select((.labels.jumpbox == "true") and (.labels.dest == $DEST) and (.labels.env == $WORKSPACE)) | .networkInterfaces[].accessConfigs[0].natIP')
  if [ -z "$newIP" ]; then
    echo "could not determine new jumphost IP from 'gcloug compute instances list'"
    usage
    exit 255
  fi
fi
if [ ! -z "$(echo $newIP | sed -E s/$ipPattern//)" ]; then
  echo "given: '$newIP' is not a valid IP"
  exit 255
fi

if [ "$forceOldIP" = "false" ]; then
  prefix="export TF_VAR_JUMPBOXIP=['\"]?"
  postfix="['\"]?"
  oldIP=$(sed -n -E -e "s/^$prefix($ipPattern)$postfix/\1/p" $REPO_ROOT_DIR/.envrc)
  if [ -z "$oldIP" ]; then echo "failed to determine oldIP from .envrc"; exit 255 ; 
  else echo "$oldIP ==> $newIP determined from .envrc"
  fi
fi

if [ "$oldIP" = "$newIP" ]; then
    echo "given IP $newIP and $oldIP oldIP are already the same. exiting."
    exit 255
fi

insideRepoFiles=($REPO_ROOT_DIR/.envrc $REPO_ROOT_DIR/provision/ssh.cfg $REPO_ROOT_DIR/00_setup/generate_known_hosts.sh)
nonRepoFiles=(~/.ssh/config ~/devTools/kubernetes/kubespray/inventory/${TF_VAR_CLUSTER_NAME}/hosts.ini)

echo "searching for matches..."
echo "inside REPO_ROOT_DIR"
grep $oldIP ${insideRepoFiles[@]} | sed -E -e "s:^${REPO_ROOT_DIR}/::"
echo ""
echo "outside REPO_ROOT_DIR"
grep $oldIP ${nonRepoFiles[@]}

read -p 'Should I go ahead and replace in these files? [yN]: ' answer
case "${answer}" in
    [yY]|[yY][eE][sS])
        echo 'ok, proceeding...' ;;
    *)
        echo 'ok, exiting...'
        exit 255
esac

oldIPpattern=${oldIP//./\\.} # escape IP dots
for f in ${insideRepoFiles[@]}; do
    sed -i '' -E -e "s/$oldIPpattern/$newIP/g" $f
done
for f in ${nonRepoFiles[@]}; do
    sed -i '' -E -e "s/$oldIPpattern/$newIP/g" $f
done
