#!/bin/bash
echo 'sourcing bash_aliases'

alias twl='terraform workspace list'
alias tw="terraform workspace list | sed -n -E 's/^\* (.*)$/\1/p'"
alias tws="terraform workspace select"
alias twdev="terraform workspace select dev"
alias twprod="terraform workspace select prod"

echo "  -> use 'twplan ' instead of 'terraform plan'"
function twplan() { ws=$(tw) ; set -x ; terraform plan -var-file ./vars/${ws}.tfvars ; set +x ; }
echo "  -> use 'twapply' instead of 'terraform apply'"
function twapply() { ws=$(tw) ; set -x ; terraform apply -var-file ./vars/${ws}.tfvars ; set +x ; }

echo ""
echo -n 'current workspace is: '
terraworkspace=$(terraform workspace list 2> /dev/null | sed -n -E 's/^\* (.*)$/\1/p')
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
