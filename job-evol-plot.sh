jobdatapath=$HOME/fifi-jobs.json
test -e "$jobdatapath" || exit 1
dst=$(jq -r '.[0].syncdir' "$jobdatapath")/evol

remotedst=leeyw101@snu-fifi-rocky:/project/leeyw101/$dst/

localdst="/mnt/Data/CQM/Calc/MuNRG/$dst/"
test -e "$localdst" || mkdir -p "$localdst"

rsync -rtvh "$remotedst" "$localdst"

sel=$(fdfind --base-directory "$localdst" | fzf)
test -z "$sel" && exit
gnuplot -c "$HOME/scripts/ghost-plot.gnuplot" "$localdst/$sel" "$@"
sleep 1 && swaymsg "[app_id=\"gnuplot_qt\"] title_format 'gnuplot: $sel'"
