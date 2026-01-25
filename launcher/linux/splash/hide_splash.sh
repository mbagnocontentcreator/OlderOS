#!/bin/bash
#
# OlderOS - Nascondi splash screen
#

PIDFILE="/tmp/olderos_splash.pid"

if [ -f "$PIDFILE" ]; then
    PID=$(cat "$PIDFILE")
    if [ -n "$PID" ] && kill -0 "$PID" 2>/dev/null; then
        kill "$PID" 2>/dev/null
    fi
    rm -f "$PIDFILE"
fi
