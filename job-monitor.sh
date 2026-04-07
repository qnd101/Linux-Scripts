#!/bin/sh

# Script for monitoring jobs in fifi over ssh
# Source job data file
# Use json format
jobdatapath=$HOME/remote-jobs.json
test -e "$jobdatapath" || exit 1

[ "$(jq '.jobs | length' "$jobdatapath")" -gt 0 ] || {
    echo "ERR: No jobs!" >&2
    exit 1
}

# Parse data out of json file
# Use only 1st element (for now)
# alias=$(jq -r '.[0].alias' "$jobdatapath" )
glo=$(jq -r '.glo' "$jobdatapath")
projPath=$glo/$(jq -r '.jobs.[0].projName' "$jobdatapath" )

SSH_OPTS="-o ControlMaster=auto -o ControlPath=/tmp/ssh-%r@%h:%p -o ControlPersist=10s"
REMOTE="leeyw101@snu-fifi-rocky"
run_ssh() {
    count=0
    until res=$(ssh $SSH_OPTS "$REMOTE" "$1" 2>/dev/null); do
        count=$((count + 1))
        [ $count -lt 3 ] || {
            echo "WRN: Failed ssh. No more retries." >&2
                    return 1
        }
        echo "WRN: Failed ssh. Retrying..." >&2
        sleep .5
    done
    echo "$res"
}

targetcnt=$(run_ssh "jq 'if type == \"array\" then length else 1 end' $projPath/results.json")
targetcnt_cur=$(run_ssh "find $projPath/results/ -type f | wc -l") || {
    # Exit if failed
    echo "ERR: Failed to find result files!" >&2
    return 1
}
jobids=$(jq -r '.jobs.[0].jobid.[]' "$jobdatapath" )
for id in $jobids; do
    res=$(run_ssh "sacct -j $id -n -X --format=State")
    if [ -n "$res" ]; then
        if [ -z "$states" ]; then
            states="$res"
        else
            # Standard POSIX way to append a literal newline
            states="$states
$res"
        fi
    fi
done
# Possible states are:
# RUNNING, COMPLETED, TIMEOUT/FAILED, PENDING, ...
total=$(echo "$states" | wc -l)
pending=$(echo "$states" | grep -cE 'PENDING')
running=$(echo "$states" | grep -cE 'RUNNING|PREEMPTED')
# failed=$(echo "$states" | grep -cE 'TIMEOUT|FAILED')
failed=0
completed=$(echo "$states" | grep -cE 'COMPLETED')
unknown=$(echo "$total - $pending -  $running - $failed - $completed" | bc)

echo "󱃣 $targetcnt_cur/$targetcnt  $pending  $running  $completed  $unknown"
