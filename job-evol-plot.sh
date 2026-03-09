#!/bin/env bash
# Shows info for (not finished) jobs
# < Option >
# '-r' : renew
# '-a' : show all jobs
while getopts "ra" opt; do
  case $opt in
    r)
      renew=true
      ;;
    a)
      showall=true
      ;;
    \?)
      echo "Invalid option: -$OPTARG" >&2
      exit 1
      ;;
  esac
done
shift $((OPTIND - 1))
jobdatapath=$HOME/remote-jobs.json
test -e "$jobdatapath" || exit 1

# Sync job files
[ "$renew" = 'true' ] && "$HOME/scripts/job-file-sync.sh"

calcmu=/mnt/Data/CQM/Calc/MuNRG

sel=$(jq -cr '.jobs.[].projName' "$jobdatapath" | while IFS= read -r projName; do
# Define the base path once for readability
base_path="$calcmu/$projName"
# Filter out lines that exist in the 'results_' list
fdfind --base-directory "$base_path/evol" --format '{/.}' | sed 's/^RhoV2_//' | \
{ ([ "$showall" = "true" ] && cat) || grep -vFf <(fdfind --base-directory "$base_path/results" --format '{/.}' | sed 's/^result_//'); } | \
awk -v proj="$projName" '{ printf "\033[32m%-30s\033[37m %s\n", proj, $1 }'
done \
| fzf --ansi)

test -z "$sel" && exit
echo "$sel"
selpath=$(echo "$sel" | awk "{ printf \"$calcmu/%s/evol/RhoV2_%s.dat\", \$1, \$2}")
echo "$selpath"
gnuplot -c "$HOME/scripts/ghost-plot.gnuplot" "$selpath" "$@"
sleep 1 && swaymsg "[app_id=\"gnuplot_qt\"] title_format 'gnuplot: $selpath'"
