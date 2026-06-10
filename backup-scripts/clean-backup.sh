#!/bin/sh

export RESTIC_PASSWORD_FILE="$HOME/.restic_pass"
export RESTIC_REPOSITORY='sftp:home-backup-ubuntu:/srv/restic-repo'

logfile="$HOME/backup.logs"
{
    echo ""
    date
    restic forget --group-by host,tags --keep-hourly 24 --keep-daily 7 --keep-monthly 12 --keep-yearly 'unlimited' --prune --compact
} >>"$logfile" 2>&1

"$HOME/scripts/backup-scripts/update-backup-cache.sh"
