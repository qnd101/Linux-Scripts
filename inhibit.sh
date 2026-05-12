#!/bin/sh

# We do NOT use the -f (fork) flag for swaylock here.
# systemd-inhibit needs the process to stay in the foreground to keep the lock active.

systemd-inhibit --why="Calculation running" \
                --mode=block \
                swaylock
