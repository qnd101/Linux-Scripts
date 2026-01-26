#!/usr/bin/env bash

SEARCH_PROMPT="Font: "
SIZE=600
POSITION="660,240"
FONT_SIZE=38
BG_COLOR="#000000"
FG_COLOR="#ffffff"
PREVIEW_TEXT="ABCDEFGHIJKLM\nNOPQRSTUVWXYZ\nabcdefghijklm\nnopqrstuvwxyz\n1234567890\n!@$\%(){}[]\n가나다라마바사"

font=$(magick -list font | awk -F: '/^[ ]*Font: /{print substr($NF,2)}' | tofi --prompt-text="$SEARCH_PROMPT")

if [ -n "$font" ]; then
    # generate_preview "$font" "$FONT_PREVIEW"
    magick -size "${SIZE}x${SIZE}" xc:"$BG_COLOR" \
        -gravity center \
        -pointsize $FONT_SIZE \
        -font "$font" \
        -fill "$FG_COLOR" \
        -annotate +0+0 "$font\n\n$PREVIEW_TEXT" \
        -flatten "png:-" \
    | swayimg "--position=$POSITION" "--size=${SIZE},${SIZE}" "--config=viewer.window=$BG_COLOR" "--config=info.show=no" "-"
fi
