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

# No -t fontSize / -t rendererType: either one makes xterm.js re-measure
# cell metrics right after connecting, which triggers a second resize
# once frotz has already drawn its opening screen -- and frotz's
# redraw-on-resize is what actually causes the mobile Chrome blank-screen
# bug (see the Dockerfile's -I /ttyd-index.html for the real fix, and its
# comment for the full writeup). Theme colors and cursorBlink don't touch
# cell metrics, so they don't trigger a re-fit and are safe here.
ttyd -W -p "$TTYD_PORT" -I /ttyd-index.html \
  -t theme="$ZORK_THEME" -t cursorBlink=true -a /select.sh &
TTYD_PID=$!

wait "$TTYD_PID"
kill "$HTTPD_PID" 2>/dev/null
