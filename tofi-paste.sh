#!/bin/sh

selected="$(cliphist list | \
    sed 's/\t/  /' | \
    tofi --prompt-text 'Paste: ' --width 720)"

if [ -n "$selected" ]; then
    echo "$selected" \
    | sed 's/  /\t/' \
    | cliphist decode \
    | wl-copy
fi
