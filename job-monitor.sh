#!/bin/sh

# Script for monitoring jobs in fifi over ssh
# Source job data file
# Use json format
jobdatapath=$HOME/fifi-jobs.json
test -e "$jobdatapath" || exit 1

# Parse data out of json file
# Use only 1st element (for now)
jobid=$(jq -r '.[0].jobid' "$jobdatapath" )
name=$(jq -r '.[0].name' "$jobdatapath" )
taskcnt=$(jq -r '.[0].taskcnt' "$jobdatapath" )
dst=$(jq -r '.[0].dst' "$jobdatapath" )
targetcnt=$(jq -r '.[0].targetcnt' "$jobdatapath" )

SSH_OPTS="-o ControlMaster=auto -o ControlPath=/tmp/ssh-%r@%h:%p -o ControlPersist=10s"
REMOTE="leeyw101@snu-fifi-rocky"
run_ssh() {
    count=0
    until res=$(ssh $SSH_OPTS "$REMOTE" "$1" 2>/dev/null); do
        count=$((count + 1))
        [ $count -lt 3 ] || return 1
        sleep .5
    done
    echo "$res"
}

targetcnt_cur=$(run_ssh "find $dst -type f | wc -l") || {
    # Exit if failed
    return 1
}
running_raw=$(run_ssh "sacct -j $jobid -n -X --format=State")
running_cur=$(echo "$running_raw" | grep -c 'RUNNING')

# Crop name if too long
test ${#name} -gt 8 && \
    name=$(printf "%.6s.." "$name")

echo "$name  $targetcnt_cur/$targetcnt  $running_cur/$taskcnt"
