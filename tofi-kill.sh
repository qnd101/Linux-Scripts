#!/bin/sh

# Fetch the list once; $1=PID, $2=PPID, $3=START, $4=COMMAND
selected="$(ps -u "$USER" -o pid,ppid,lstart,comm,rss --no-headers | \
    awk '{printf "%s  %s %s  %-15s %6.1fM  %-20s \n", $1, $3, $6, $8, $8/1024, $2}' | \
    tofi --width 750 --prompt-text "Kill: ")"

if [ -n "$selected" ]; then
    selpid=$(echo "$selected" | awk '{print $1}')
    selcomm=$(echo "$selected" | awk '{print $4}')

    answer="$(printf "No\nYes" | tofi --prompt-text "Kill $selpid $selcomm? ")"

    if [ "$answer" = "Yes" ]; then
        kill -15 "$selpid"
    fi
fi
