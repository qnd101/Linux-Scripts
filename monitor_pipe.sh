#!/bin/env bash

PIPE=/tmp/backup-json-pipe

# Create the named pipe if it doesn't already exist
if [ ! -p "$PIPE" ]; then
    mkfifo "$PIPE"
fi

echo "{\"text\": \"1972-11-21\"}"

# Continuous loop to read from the pipe
while [ -p "$PIPE" ]; do
    if read -r line < "$PIPE"; then
        # echo "$line"
        if [[ -z "$line" ]]; then
            echo "{\"text\":\"1972-11-21\"}"
            continue
        fi
        msg_type=$(jq -r '.message_type // ""' <<< "$line")
        case "$msg_type" in
            "status")
                num=$(jq -r '.percent_done // ""' <<< "$line")
                percentage=$(echo "$num * 100" | bc)
                notify-send "{\"text\":\"Backup: $percentage%\",\"alt\":\"running\"}"
                echo "{\"text\":\"Backup: $percentage%\",\"alt\":\"running\"}"
                ;;
            # "summary")
            #     end_time="$(jq -r '.backup_end // ""' <<< "$line")"
            #     echo "$end_time"
            #     ;;
        esac
    fi
done


