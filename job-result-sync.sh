localdst="$1/"
test -z "$1" && localdst='./'

test -e "$localdst" || mkdir -p "$localdst"

jobdatapath=$HOME/fifi-jobs.json
test -e "$jobdatapath" || exit 1

dst=$(jq -r '.[0].dst' "$jobdatapath" )

rsync -rtvh "leeyw101@snu-fifi-rocky:$dst" "$localdst"
