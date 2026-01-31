#!/bin/env bash

notify_json() {
    # Process input line by line as it arrives
    while read -r line; do
        echo "$line"
        # Skip empty lines or non-JSON input
        if [[ -z "$line" ]] || ! echo "$line" | jq -e . > /dev/null 2>&1; then
            continue
        fi

        # Extract data using local variables to avoid namespace pollution
        local msg_type=$(jq -r '.message_type // "Notification"' <<< "$line")
        local msg_body=$(jq -r '.message // "No content"' <<< "$line")
        local msg_code=$(jq -r '.code // ""' <<< "$line")

        # Build the notification title
        local title="$msg_type"
        [[ -n "$msg_code" ]] && title="$title (Code: $msg_code)"

        # Send notification immediately
        notify-send '--app-name=restic' "$title" "$msg_body" '--urgency=critical'
    done
}

backup_dir=/mnt/Data/
export RESTIC_PASSWORD_FILE="$HOME/.restic_pass"
export RESTIC_REPOSITORY='sftp:home-backup-ubuntu:/srv/restic-repo'

parent=$(restic --json snapshots --latest 1 -H "$(hostname -s)" | jq -r 'max_by(.time) | .id')

if [ "$parent" != 'null' ]; then
    P1="--parent"
    P2="$parent"
fi

# backup_files="$(fdfind -H0 -t f -t l --one-file-system --base-directory "$backup_dir")"
# json_stream=/tmp/backup-json-pipe
# if ! [ -p "$json_stream" ]; then
#     json_stream=/dev/null
# fi

# Generate a log for backup
# restic --json backup "$P1" "$P2" --files-from-raw \
#     <(fdfind -H0 -a -t f -t l --one-file-system --base-directory "$backup_dir") \
#     2>&1 \
#     1>$json_stream | notify_json
# Send empty line
# echo -e "\n" > $json_stream


SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
logfile="$SCRIPT_DIR/log/backup.logs"

echo "" >> "$logfile"
date >> "$logfile"
restic backup "$P1" "$P2" --files-from-raw \
    <(fdfind -H0 -a -t f -t l --one-file-system --base-directory "$backup_dir") \
    2>&1 \
    1>>"$logfile" | notify_json
