#!/bin/sh
# Saves snapshot history to a json cache
export RESTIC_PASSWORD_FILE="$HOME/.restic_pass"
export RESTIC_REPOSITORY='sftp:home-backup-ubuntu:/srv/restic-repo'
# Note: Since I specify every file whenever I make a backup, the paths change every time I create a snapshot
# Therefore most snapshots are assigned a different restic group (specified by host + path)
# Due to this, --latest 1 can't find the latest snapshot. It gives the latest snapshot per group, and we need to filter it again using jq.
restic --json snapshots -H "$(hostname -s)" | jq 'map({id:.id, time:.time, parent:.parent, summary:.summary})' > "$HOME/backup-snapshots.json"
