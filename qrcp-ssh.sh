#!/bin/sh
cleanup() {
    if [ -n "$SSH_PID" ]; then
        printf "\nCleaning up ssh tunnel... (PID: %s)\n" $SSH_PID
        kill -15 $SSH_PID
    fi
    exit 1
}

trap cleanup INT TERM

# 5 minute timeout, in case script crashes
ssh -R 6677:localhost:80 leeyw@home-util-ubuntu "sleep 300" & 
SSH_PID=$!

# Map parameters sent to script
qrcp "$@" --interface lo --port 80 --fqdn qrcp.leeyw101.pe.kr

# If send, we need to wait until the client finishes download
if [ "$1" = 'send' ]; then
    printf "Press Enter if download finished..."
    read -r _
fi

kill -15 $SSH_PID
echo 'Bye.'
