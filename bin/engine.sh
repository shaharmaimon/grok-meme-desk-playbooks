#!/usr/bin/env bash
# engine.sh start|stop|restart|status — ONLY for the experimental "engine on the box" topology (paper only). Unused when the engine runs on the VPS.
WS="${WORKSPACE:-/workspace/desk}"; E="$WS/engine"; PID="$E/engine.pid"; NODE="$(command -v node || echo "$WS/tools/node/bin/node")"
alive() { [ -f "$PID" ] && kill -0 "$(cat "$PID")" 2>/dev/null; }
case "${1:-status}" in
  start)   alive && { echo "engine running pid=$(cat "$PID")"; exit 0; }; [ -f "$E/dist/engine.js" ] || { echo "no $E/dist/engine.js"; exit 2; }
           (cd "$E" && setsid nohup "$NODE" dist/engine.js >> "$WS/logs/engine.log" 2>&1 < /dev/null & echo $! > "$PID"); sleep 2; alive && echo "engine started" || { echo "engine failed"; exit 1; } ;;
  stop)    alive && kill "$(cat "$PID")" && echo "engine stopped" || echo "engine not running" ;;
  restart) "$0" stop; sleep 2; "$0" start ;;
  status)  alive && echo "engine alive" || { echo "engine DEAD"; exit 1; } ;;
esac
