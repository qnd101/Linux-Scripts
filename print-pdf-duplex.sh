#!/bin/sh

# Check if a file path was provided
if [ -z "$1" ]; then
    echo "Usage: $0 <path-to-pdf>"
    exit 1
fi

FILE_PATH="$1"

# 1. List printers and let the user choose
echo "Available Printers:"
i=1
printers=$(lpstat -e)
echo "$printers" | while read -r line; do
    echo "$i) $line"
    i=$((i + 1))
done

printf "Choose a Printer (index): "
read -r choice

# Extract the specific printer name based on index
PRINTER=$(echo "$printers" | sed -n "${choice}p")

if [ -z "$PRINTER" ]; then
    echo "Invalid selection."
    exit 1
fi

# 2. Get the page range
printf "Range (min-max, e.g., 1-10): "
read -r range
MIN=$(echo "$range" | cut -d'-' -f1)
MAX=$(echo "$range" | cut -d'-' -f2)

# 3. Calculate page sets
FIRST_SET=""
SECOND_SET=""
START_PARITY=$((MIN % 2))

# Generate First Set (Forward order, will be reversed by CUPS)
curr=$MIN
while [ "$curr" -le "$MAX" ]; do
    if [ $((curr % 2)) -ne "$START_PARITY" ]; then
        if [ -z "$FIRST_SET" ]; then FIRST_SET="$curr"; else FIRST_SET="$FIRST_SET,$curr"; fi
    fi
    curr=$((curr + 1))
done

# Generate Second Set (Forward order)
curr=$MIN
while [ "$curr" -le "$MAX" ]; do
    if [ $((curr % 2)) -eq "$START_PARITY" ]; then
        if [ -z "$SECOND_SET" ]; then SECOND_SET="$curr"; else SECOND_SET="$SECOND_SET,$curr"; fi
    fi
    curr=$((curr + 1))
done

# 4. Execution
echo "Printing first stack in REVERSE (Pages: $FIRST_SET)..."
# Added -o outputorder=reverse here
lp -d "$PRINTER" -P "$FIRST_SET" -o outputorder=reverse "$FILE_PATH"

printf "Flip the stack and press Enter to continue..."
read -r _

echo "Printing second stack (Pages: $SECOND_SET)..."
lp -d "$PRINTER" -P "$SECOND_SET" "$FILE_PATH"

echo "Done!"
