#!/bin/sh

# Usage: ./script.sh <path> <range>
PATH_ARG="$1"
RANGE_ARG="$2"

# Sanitize input filepath and get absolute path
[ -f "$PATH_ARG" ] || {
    echo "ERR: File '$PATH_ARG' does not exist!" >&2
    exit 1
}

echo "$PATH_ARG" | grep '.pdf$' || {
    echo "WRN: file '$PATH_ARG' does not have a pdf extension."
    printf "Ctrl-C to terminate. To continue, press Enter: "
    read -r _
}

# Ensure we have a full absolute path for the URL
ABS_PATH=$(realpath "$PATH_ARG")

# Helper function to copy file URL to clipboard
copy_as_url() {
    file_path="$1"
    # Format as file://... and copy using text/uri-list MIME type
    echo "file://$file_path" | wl-copy -t text/uri-list
    echo "Successfully copied file URL into clipboard: file://$file_path"
}

# If range is not given, copy the original file URL
if [ -z "$RANGE_ARG" ]; then
    copy_as_url "$ABS_PATH"
    exit 0
fi

# If range is given, validate format 'start-end'
if ! echo "$RANGE_ARG" | grep -Eq '^[0-9]+-[0-9]+$'; then
    echo "ERR: Invalid range! format: 'start-end'" >&2
    exit 1
fi

# Setup temporary directory
OUTPUT_FOLDER="/tmp/PdfCopy"
mkdir -p "$OUTPUT_FOLDER"

# Synthesize output path
BASE_NAME=$(basename "$ABS_PATH" | sed 's/\.[^.]*$//')
OUTPUT_PATH="$OUTPUT_FOLDER/${BASE_NAME}_${RANGE_ARG}.pdf"

# Generate sliced file with mutool
mutool clean "$ABS_PATH" "$OUTPUT_PATH" "$RANGE_ARG"

# Copy the new file's URL to clipboard
if [ -f "$OUTPUT_PATH" ]; then
    copy_as_url "$OUTPUT_PATH"
else
    echo "ERR: Failed to create $OUTPUT_PATH" >&2
    exit 1
fi
