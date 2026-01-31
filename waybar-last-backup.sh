#!/bin/env bash

export RESTIC_PASSWORD_FILE='/home/leeyw/.restic_pass'
export RESTIC_REPOSITORY='sftp:home-backup-ubuntu:/srv/restic-repo'

dt_iso="$(restic --json snapshots --latest 1 -H "$(hostname -s)" | jq -r 'max_by(.time) | .summary.backup_start')"


if [ -z "$dt_iso" ]; then
    echo "Disconnected"
    exit
fi

dt_text="$(date -d "$dt_iso" +"%H:%M %m/%d")"

echo "$dt_text"
# echo "{\"text\":\"$dt_text\"}"
