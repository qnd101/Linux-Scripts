#!/bin/env bash

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

DATA_PATH="$SCRIPT_DIR/math_unicode.csv"

result=$(column -s, -t "$DATA_PATH" | tofi --width 500 --height 300 --font 'monospace' --prompt-text 'Symbol: ' | awk '{print $2}')

wtype "$result"
