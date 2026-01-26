#!/usr/bin/env bash

filename="$(date +%Y-%m-%d_%H-%m-%s).png"
dstpath="$HOME/screenshots/$filename"
echo $dstpath
grim -g "$(slurp)" "$dstpath"
if [ $? -eq 0 ]; then
	wl-copy -t text/uri-list <<< "file://$dstpath"
	notify-send "Screenshot saved & copied" "$filename" --app-name "grim"
fi


