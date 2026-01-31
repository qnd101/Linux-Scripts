#!/usr/bin/env bash

# Fetch the list once; $1=PID, $2=PPID, $3=START, $4=COMMAND
selected="$(ps -u "$USER" -o pid,ppid,bsdstart,comm --no-headers | \
    awk '{printf "%s  %s  %-20s <%s\n", $1, $3, $4, $2}' | \
    tofi --prompt-text "Kill: ")"

if [[ -n $selected ]]; then
    # Extract just the PID (first column) and Command (third column) for the prompt
    selpid=$(echo "$selected" | awk '{print $1}')
    selcomm=$(echo "$selected" | awk '{print $3}')

    answer="$(echo -e "No\nYes" | tofi --prompt-text "Kill $selcomm ($selpid)? ")"

    if [[ $answer == "Yes" ]]; then
        kill -9 "$selpid"
    fi
fi
