#!/usr/bin/env bash

selected="$(ps -u "$USER" -o pid,bsdstart,comm --no-headers | tofi --prompt-text "Kill: " | awk '{print $1 " " $3}')"

if [[ ! -z $selected ]]; then

    answer="$(echo -e "No\nYes" | \
            tofi --prompt-text "Kill $selected? ")"

    if [[ $answer == "Yes" ]]; then
        selpid="$(awk '{print $1}' <<< "$selected")"; 
        kill -9 "$selpid"
    fi
fi

exit 0
