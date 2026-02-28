#!/bin/sh
backup_cache=$HOME/backup-snapshots.json
test -e "$backup_cache" || {
    echo "ERR: $backup_cache does not exist!" >&2
    exit 1
}

dt_iso=$(jq -r 'max_by(.time) | .time' "$backup_cache")

test -z "$dt_iso" && {
    echo "ERR: cannot find backup time!" >&2
    exit 1
}

dt_text=$(date -d "$dt_iso" +"%H:%M %m/%d")

echo "$dt_text"
