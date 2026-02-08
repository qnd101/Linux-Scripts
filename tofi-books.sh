#!/bin/sh

books='/mnt/Data/Books'
selected=$(rg --files $books \
    | rg '.pdf$' | sed "s|^$books/||" \
    | tofi --width=800 --prompt-text "Books: ")
if [ -n "$selected" ]; then
    xdg-open "$books/$selected"
fi

