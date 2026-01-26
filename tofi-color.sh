#!/bin/env bash

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
echo "$SCRIPT_DIR"

IMAGE_PATH="$SCRIPT_DIR/tofi-color-data/pastel-colors.png"
SCREEN_W=1920
SCREEN_H=1080

read -r IMG_W IMG_H <<< "$(identify -format "%w %h" "$IMAGE_PATH")"

POS_X=$(( SCREEN_W / 2 + 20 ))
POS_Y=$(( (SCREEN_H - IMG_H) / 2 ))

# 4. Execute swayimg
swayimg \
  "--position=$POS_X,$POS_Y" \
  "--size=$IMG_W,$IMG_H" \
  '--config=viewer.window=#000000' \
  '--config=info.show=no' \
  "$IMAGE_PATH" &
IMG_PID=$!

sleep 0.05

RESULT=$(cat "$SCRIPT_DIR/tofi-color-data/pastel-colors.txt" | tofi '--width' '600' '--height' '400' '--margin-right=980' '--margin-top=340' '--anchor=top-right' '--prompt-text' 'Color: ')

if [ -n "$RESULT" ]; then
    cut -d ' ' -f 2 <<< "$RESULT" | tr -d '\n' | wl-copy
fi

kill $IMG_PID 2>/dev/null && echo "Process $IMG_PID killed." || echo "Process $IMG_PID was not running."
