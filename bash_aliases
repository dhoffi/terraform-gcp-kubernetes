#!/bin/bash

if [[ $- == *i* ]] ; then
    echo "sourcing ./bash_aliases"
fi

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" > /dev/null && pwd )"

alias twl='terraform workspace list'
#alias tw="terraform workspace list | sed -n -E 's/^\* (.*)$/\1/p'"
function tw() { cat $DIR/.terraform/environment ; if [[ $- == *i* ]]; then echo ; fi ; }
alias tws="terraform workspace select"
alias twdev="terraform workspace select dev"
alias twprod="terraform workspace select prod"

echo "  -> use 'twplan ' instead of 'terraform plan'"
function twplan() { ws=$(tw) ; set -x ; time terraform plan -var-file ./vars/${ws}.tfvars ; set +x ; }
echo "  -> use 'twapply' instead of 'terraform apply'"
function twapply() { ws=$(tw) ; set -x ; time terraform apply -var-file ./vars/${ws}.tfvars ; set +x ; }
echo "  -> use 'twdestroy' instead of 'terraform destroy'"
function twdestroy() { ws=$(tw) ; set -x ; time terraform destroy -var-file ./vars/${ws}.tfvars ; set +x ; }

echo ""
echo -n 'current workspace is: '
if [ -f ".terraform/environment" ]; then terraworkspace=$(cat $DIR/.terraform/environment); else terraworkspace="unknown"; fi
if [ $? -eq 0 ]; then
  case $terraworkspace in
  test)
    ;&
  dev)
    echo -e "\e[1;33m$terraworkspace\e[0m"
    ;;
  prod)
    echo -e "\e[1;31m$terraworkspace\e[0m"
    ;;
  *)
    echo "$terraworkspace"
  esac
else
  echo -e "\e[1;31munknown\e[0m"
fi
