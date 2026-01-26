#!/usr/bin/env bash

selected="$(cliphist list | \
    sed 's/\t/  /' | \
    tofi --prompt-text 'Paste: ' --width 720)"
if [[ ! -z $selected ]]; then
    sed 's/  /\t/' <<< "$selected" | \
        cliphist decode | \
        wl-copy
fi
