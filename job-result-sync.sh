jobdatapath=$HOME/fifi-jobs.json
test -e "$jobdatapath" || exit 1
dst=$(jq -r '.[0].dst' "$jobdatapath" )

remotedst=leeyw101@snu-fifi-rocky:/project/leeyw101/$dst/

localdst="/mnt/Data/CQM/Calc/MUNRG-Fifi/$dst/"
test -e "$localdst" || mkdir -p "$localdst"

rsync -rtvh "$remotedst" "$localdst"
