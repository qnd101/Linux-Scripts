#!/bin/sh

# 1. Get user processes sorted by CPU usage
# we use -u to filter by current user and -o for specific columns
# 'pcpu' is the CPU percentage, 'pid' is the ID, and 'args' is the command
# The 'tail -n +2' removes the header row
selection=$(ps -u "$(id -u)" -o pcpu,pid,comm --sort=-pcpu | tail -n +2 | \
    awk '{printf "%-6s %-8s %s\n", $1"%", $2, $3}' | \
    fzf --header="Select a process to limit (CPU% PID COMMAND)")

# Exit if no selection was made (e.g., user pressed ESC)
[ -z "$selection" ] && exit 0

# Extract the PID (the second column in our ps output)
pid=$(echo "$selection" | awk '{print $2}')

# 2. Prompt for CPU limit
printf "Enter CPU limit percentage: "
read -r limit

# Validate that the limit is a number
case $limit in
    ''|*[!0-9]*) 
        echo "Error: Please enter a valid integer."
        exit 1 
        ;;
esac

# 3. Apply the limit using cpulimit
echo "Applying $limit% limit to PID $pid..."
cpulimit -p "$pid" -l "$limit"
