#!/bin/bash

if [[ $- == *i* ]]; then
  echo "sourcing ./bash_aliases"
fi

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null && pwd)"

alias twl='terraform workspace list'
#alias tw="terraform workspace list | sed -n -E 's/^\* (.*)$/\1/p'"
function tw() {
  cat $DIR/.terraform/environment
  if [[ $- == *i* ]]; then echo; fi
}
alias tws="terraform workspace select"
alias twdev="terraform workspace select dev"
alias twprod="terraform workspace select prod"

# example ~/.ssh/config
# # private network with master and worker nodes
# Host 10.0.1.*
#   User         devtest-jbadmin
#   IdentityFile ~/.ssh/gcp-devtest-jumpbox
#   ProxyJump    devtest-jumpbox
#
# Host devtest-jumpbox 35.240.83.153
#   Hostname     35.240.83.153
#   User         devtest-jbadmin
#   IdentityFile ~/.ssh/gcp-devtest-jumpbox
#   # # settings for using SSH multiplexing (e.g. for using ansible over jumpbox)
#   # ControlMaster auto
#   # ControlPath ~/.ssh/ansible-%r@%h:%p
#   # ControlPersist 5m
#
# # on local laptop use: ssh -nNT k8stunnel
# Host k8stunnel
#   Hostname     10.0.1.3
#   User         devtest-jbadmin
#   IdentityFile ~/.ssh/gcp-devtest-jumpbox
#   ProxyJump    devtest-jumpbox
#   LocalForward 6443 localhost:6443
echo "  -> use 'k8stunnel' to tunnel localhost:6443 ==> 10.0.1.x:6443"
alias k8stunnel='ssh -nNT k8stunnel'
echo "  -> use 'twplan ' instead of 'terraform plan'"
function twplan() {
  ws=$(tw)
  set -x
  time terraform plan -var-file ./vars/${ws}.tfvars
  set +x
}
echo "  -> use 'twapply' instead of 'terraform apply'"
function twapply() {
  ws=$(tw)
  set -x
  time terraform apply -var-file ./vars/${ws}.tfvars
  set +x
}
echo "  -> use 'twdestroy' instead of 'terraform destroy'"
function twdestroy() {
  ws=$(tw)
  set -x
  time terraform destroy -var-file ./vars/${ws}.tfvars
  set +x
}

echo ""
echo -n 'current workspace is: '
if [ -f ".terraform/environment" ]; then terraworkspace=$(cat $DIR/.terraform/environment); else terraworkspace="unknown"; fi
if [ $? -eq 0 ]; then
  case $terraworkspace in
  test) ;&

  dev)
    echo -e "\e[1;33m$terraworkspace\e[0m"
    ;;
  prod)
    echo -e "\e[1;31m$terraworkspace\e[0m"
    ;;
  *)
    echo "$terraworkspace"
    ;;
  esac
else
  echo -e "\e[1;31munknown\e[0m"
fi

function ffr() {
  if [ -z "$1" ] || [ -z "$2" ]; then echo "synopsis: ffr <searchRegex> <replaceString>";
  else
    find . -type d \( -path '*/.*' -o -name bin -o -name build -o -name target -o -name gradle -o -name node_modules \) -prune -o -type f -exec sed -i '' -E -e "s/$1/$2/g" {} +
  fi
}

function replaceMultiThingsInOneFile() {
  if [ "$(($# % 2))" -eq 0 ] || [ "$#" -lt 3 ]; then echo "need odd number of parameters of at least 3!"; fi
  if [ -z "$1" ] || [ -z "$2" ] || [ -z "$3" ]; then
    echo "synopsis: replaceMultiThingsInOneFile <filename> <searchString1> <replaceString1> <searchString2> <replaceString2> ... "
    return
  fi
  filename=$1
  shift
  if [ ! -e "$filename" ]; then
    echo "$filename does not exist!"
    return
  fi

  while (("$#" >= 2)); do
    searchString=$(echo $1 | sed -e 's/[]\/$*.^[]/\\&/g')
    replaceString=$2
    grep $1 $filename >/dev/null 2>&1
    if [ $? -ne 0 ]; then echo "no match for '$1' found in $filename"; fi
    sed -i '' -e "s/$searchString/$replaceString/g" $filename
    shift 2
  done
}

function replaceOneThingInMultiFiles() {
  if [ "$#" -lt 3 ]; then echo "need at least 3 parameters!"; fi
  if [ -z "$1" ] || [ -z "$2" ] || [ -z "$3" ]; then
    echo "synopsis: replaceOneThingInMultiFiles <searchString> <replaceString> <filename(s)> "
    return
  fi
  origString=$1
  searchString=$(echo $1 | sed -e 's/[]\/$*.^[]/\\&/g')
  replaceString=$2
  shift 2

  while (("$#" >= 1)); do
    filename=$1
    if [ ! -e "$filename" ]; then echo "$filename does not exist!"; fi
    grep $origString $filename >/dev/null 2>&1
    if [ $? -ne 0 ]; then echo "no match for '$origString' found in $filename"; fi
    sed -i '' -e "s/$searchString/$replaceString/g" $filename
    shift
  done
}

### coding helpers

# # does not work for structures with nested braces
# /{/                    if current line contains{then execute next block
# {                      start block
#     :1;                label for code to jump to
#     /}/!               if the line does not contain}then execute next block
#     {                  start block
#         N;             add next line to pattern space
#         b1             jump to label 1
#     };                 end block
#     /event/p           if the pattern space contains the search string, print it
#                        (at this point the pattern space contains a full block of lines from{to})
# };                     end block
# d                      delete pattern space
#
# for recursive usage u may use this:
# for d in $(find . -type d \( -name '.git' -o -name '.terraform' \) -prune -o -type f -name '*.tf' -print); do extractBraced output $d; done
# or with shopt -s globstar
# for f in ./**/*.tf; do extractBraced output $f ; done
function extractBraced() {
  if [ -z "$1" ] || [ -z "$2" ]; then
    echo "synopsis: extractBraced <prefix> <fileGlobs>"
    echo "      eg: extractBraced output *.tf"
    return
  fi
  prefix=$1
  shift
  for f in ${*}; do
    echo "# from $f"
    # only works with gnu sed, so on mac osx do 'brew install gnu-sed' and use gsed instead of sed
    gsed "/$prefix.* {/{:1; /[^{]} *$/!{N; b1}; /$prefix.* /p}; d" $f
  done
}

# getting some info from compute instances (vms)
function gcinstances() {
  local=false
  myQuery='(.labels.node == "worker")'
  AND=' and '
  theColumns='.networkInterfaces[].networkIP,.name,"tags[",.tags.items[],"]"'
  for par in "$@"; do
    case $par in
    all)
      myQuery=''
      AND=''
      ;;
    node)
      myQuery='((.labels.node == "master") or (.labels.node == "worker"))'
      ;;
    worker)
      myQuery='(.labels.node == "worker")'
      ;;
    master)
      myQuery='(.labels.node == "master")'
      ;;
    jumpbox)
      myQuery='(.labels.jumpbox == "true")'
      ;;
    ip)
      theColumns='.networkInterfaces[].networkIP'
      ;;
    ipname)
      theColumns='.networkInterfaces[].networkIP,.name'
      ;;
    local)
      local=true
      ;;
    info) ;;

    *)
      echo "unknown parameter: $par"
      ;;
    esac
  done

  selectEnvPostfix=$(printf '%s((.labels.dest == "%s") and (.labels.env == "%s"))' "$AND" $DEST $(cat $REPO_ROOT_DIR/.terraform/environment))
  theSelect=$(printf '%s%s' "$myQuery" "$selectEnvPostfix")

  theJqQuery=$(printf '.[] | select(%s) | [%s] | join(" ")' "$theSelect" "$theColumns")

  mkdir -p $REPO_ROOT_DIR/tmp
  outfile=$REPO_ROOT_DIR/tmp/$DEST-$(cat $REPO_ROOT_DIR/.terraform/environment)-instances.json
  if [ "$local" = "false" ]; then
    gcloud compute instances list --format=json >$outfile
  fi

  jq -r "$theJqQuery" $outfile | sort
}
export -f gcinstances
