#!/bin/sh

# Move to script directory
cd "$(dirname "$0")" || exit

DATA_PATH="./math_unicode.csv"

result=$(column -s, -t "$DATA_PATH" | tofi --width 600 --height 300 --font 'monospace' --prompt-text 'Symbol: ' | awk '{print $2}')

wtype "$result"
