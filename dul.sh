#!/bin/sh
## This script lists the disk usage of all files/directories under the currrent directory
TARGET="${1:-.}"

# ANSI color codes
SIZE_COL='\033[1;32m' # Bright Green
DIR_COL='\033[1;34m'  # Bright Blue
FILE_COL='\033[1;36m' # Bright Cyan
RESET='\033[0m'

# Find, calculate sizes, and sort
find "$TARGET" -mindepth 1 -maxdepth 1 -exec du -sh {} + 2>/dev/null |
    sort -h |
    while IFS="$(printf '\t')" read -r size path; do

        # Strip leading ./ for a cleaner display
        clean_path="${path#./}"

        # Check if the path is a directory
        if [ -d "$path" ]; then
            # Color directories blue and append a trailing slash
            printf "${SIZE_COL}%s${RESET}\t${DIR_COL}%s/${RESET}\n" "$size" "$clean_path"
        else
            # Color files cyan
            printf "${SIZE_COL}%s${RESET}\t${FILE_COL}%s${RESET}\n" "$size" "$clean_path"
        fi
    done
