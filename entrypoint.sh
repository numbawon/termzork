#!/bin/sh
# Two processes, one container: busybox httpd serves the landing page on
# HTTP_PORT, ttyd serves the game on TTYD_PORT. Neither needs root -- both
# bind non-privileged ports -- so this runs as a single non-root user
# start to finish.
set -e

HTTP_PORT="${HTTP_PORT:-8080}"
TTYD_PORT="${TTYD_PORT:-7681}"

httpd -f -p "$HTTP_PORT" -h /landing &
HTTPD_PID=$!

trap 'kill "$HTTPD_PID" 2>/dev/null; exit 0' TERM INT

ttyd -W -p "$TTYD_PORT" -t theme="$ZORK_THEME" -t cursorBlink=true \
  -t fontSize=15 -t rendererType=dom -a /select.sh &
TTYD_PID=$!

wait "$TTYD_PID"
kill "$HTTPD_PID" 2>/dev/null
