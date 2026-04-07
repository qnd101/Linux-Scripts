#!/bin/sh

export RESTIC_PASSWORD_FILE="$HOME/.restic_pass"
export RESTIC_REPOSITORY='sftp:home-backup-ubuntu:/srv/restic-repo'
restic mount /restic/
