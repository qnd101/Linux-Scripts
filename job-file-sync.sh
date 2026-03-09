#!/bin/sh
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
done
