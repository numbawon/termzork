#!/bin/sh
# ttyd's wrapped command (`ttyd -a select.sh`). `-a/--url-arg` lets the
# client pass ?arg=... on the URL, forwarded here as $1 -- that's how one
# ttyd process serves three different games with no per-game container
# and no real Unix user-switching (which would need root/setuid).
case "$1" in
  zork1) exec frotz /games/zork1.z3 ;;
  zork2) exec frotz /games/zork2.z3 ;;
  zork3) exec frotz /games/zork3.z3 ;;
  *)
    echo "No game selected."
    echo "Open the landing page and pick one, or visit this URL with"
    echo "?arg=zork1, ?arg=zork2, or ?arg=zork3 on the end."
    ;;
esac
