#!/bin/env bash

notes='/mnt/Data/Notes'
selected=$(rg --files $notes \
    | rg '.pdf$' | sed "s|^$notes/||" \
    | tofi --prompt-text "Notes: ")
if [ -n "$selected" ]; then
    xdg-open "$notes/$selected"
fi
