#!/bin/sh

# Assert 1st input is a valid markdown file
file=$1
! [ "${file##*.}" = 'md' ] || {
    echo "ERR: Provide a .md file!" >&2
}
test -e "$file" || {
    echo "ERR: File $file does not exist" >&2
}
# Is dst is not provided, create a file in tmp
dst_html=$2
test -z "$dst_html" && dst_html=$(mktemp "${TMPDIR:-/tmp}/tmp.XXXXXX.html")
# Convert markdown into html using pandoc
pandoc -o "$dst_html" --css "file:///$HOME/scripts/markdown.css" -s -f markdown+hard_line_breaks "$file" -V header-includes="<script src=\"file:///$HOME/scripts/markdown.js\"></script>"
# Open html using Cog browser
cog --platform=wl --doc-viewer "--gapplication-app-id=com.igalia.Cog$$" "$dst_html"
