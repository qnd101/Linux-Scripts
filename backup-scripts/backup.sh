#!/bin/env bash

backup_dir=/mnt/Data/
export RESTIC_PASSWORD_FILE="$HOME/.restic_pass"
export RESTIC_REPOSITORY='sftp:home-backup-ubuntu:/srv/restic-repo'

parent=$(restic --json snapshots --latest=1 -H "$(hostname -s)" | jq -r 'max_by(.time) | .id')

if [ "$parent" != 'null' ]; then
    P1="--parent" P2="$parent"
fi

# SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
logfile="$HOME/backup.logs"
max_log_size=$((5 * 1024 * 1024))

{
    echo "";
    date;
    restic backup "$P1" "$P2" --files-from-raw \
        <(fdfind -H0 -a -t f -t l --one-file-system --base-directory "$backup_dir");
    restic forget --group-by host,tags --keep-hourly 24 --keep-daily 7 --keep-monthly 12 --keep-yearly 2 --prune;
} >> "$logfile" 2>&1

if [ -f "$logfile" ] && [ "$(wc -c < "$logfile")" -gt "$max_log_size" ]; then
    temp_log="${logfile}.tmp"
    tail -c "$max_log_size" "$logfile" > "$temp_log" && mv "$temp_log" "$logfile"
fi

# Autoremove old snapshots
# Update cache
"$HOME/scripts/backup-scripts/update-backup-cache.sh"
