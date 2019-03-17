#!/bin/bash

if [ -z "$REPO_ROOT_DIR" ]; then echo 'you have to `source .envrc` in project root dir or consider installing https://direnv.net' ; exit -1 ; fi
trap "set +x" INT TERM QUIT EXIT

if [ -z "$1" ]; then echo 'you have to give inventory.ini path as parameter' ; exit -1 ; fi
if [ ! -s "$1" ]; then echo "file $1 does not exist!" ; exit -1 ; fi

inventoryfile=$1

type gcinstances &>/dev/null
if [ $? -ne 0 ]; then echo 'you have to source bash_aliases (to have gcinstances function defined)' ; exit -1 ; fi



lead='### BEGIN GENERATED CONTENT'
tail='### END GENERATED CONTENT'

instancetypes=("master" "worker")
cp $inventoryfile $inventoryfile.new
for what in "${instancetypes[@]}"; do
    # check
    if ! grep "$lead $what" $inventoryfile > /dev/null ; then >&2 echo "no '$lead $what' found in $inventoryfile ... skipping" ; continue ; fi
    if ! grep "$tail $what" $inventoryfile> /dev/null ; then >&2 echo "no '$lead $what' found in $inventoryfile ... skipping" ; continue ; fi
    # everything up to (excluding) $lead
    sed  -e "/^$lead $what/,$ d" $inventoryfile.new > $inventoryfile.xtmpx
    echo "$lead $what" >> $inventoryfile.xtmpx
    >&2 echo "getting instance ips for $what ..."
    gcinstances $what ip >> $inventoryfile.xtmpx
    # everything after (including) $tail
    sed -ne "/^$tail $what/,$ p" $inventoryfile.new >> $inventoryfile.xtmpx
    mv $inventoryfile.xtmpx $inventoryfile.new
done

echo '---'
echo 'check with:'
echo "diff $inventoryfile.new $inventoryfile"
echo ''
echo 'if no errors you can overwrite the original with the generated one:'
echo "mv $inventoryfile.new $inventoryfile"