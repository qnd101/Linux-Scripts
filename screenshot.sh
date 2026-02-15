#!/bin/sh

filename="$(date +%Y-%m-%d_%H-%m-%s).png"
dstfoler=/tmp/screenshots
if ! [ -e $dstfoler ]; then
    mkdir $dstfoler
fi
dstpath="$dstfoler/$filename"

echo "$dstpath"

if ! grim -g "$(slurp)" "$dstpath"; then exit 1; fi

echo "file://$dstpath" | wl-copy -t text/uri-list
notify-send "Screenshot copied" "$filename" --app-name "screenshot.sh"

sleep 0.1

filename=$(printf "\n" \
    | tofi --prompt-text 'Save as (.png): ' --require-match=false --width=600 --height=100 \
    | tr -d '\n')

if [ -z "$filename" ]; then exit 0; fi

# Prevent command injection
case "$filename" in
        -*) return 1 ;;
esac

savepath="$HOME/screenshots/$filename.png"
if cp "$dstpath" -T "$savepath"; then
    notify-send "Screenshot saved" "in $savepath" --app-name "screenshot.sh"
else
    notify-send "Failed to save screenshot" "in ~/screenshots/$filename.png" --app-name "screenshot.sh"
fi
