#!/bin/sh
[ "$1" = '--nosend' ] && nosend=true
jobdatapath=$HOME/remote-jobs.json
test -e "$jobdatapath" || exit 1

remote=$(jq -r '.remote' "$jobdatapath")
glo=$(jq -r '.glo' "$jobdatapath")

jq -cr '.jobs.[].projName' "$jobdatapath" | while IFS= read -r projName; do
echo "Synchronizing $projName..."

remotedst=$remote:$glo/$projName/
localdst="/mnt/Data/CQM/Calc/MuNRG/$projName/"

test -e "$localdst" || mkdir -p "$localdst"
rsync -rtvh "$remotedst" "$localdst"

# Resume files are synced in opposite way
test -z "$nosend" && rsync -rtvh "$localdst/resume/" "$remotedst/resume/"
done
