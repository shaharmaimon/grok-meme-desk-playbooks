#!/usr/bin/env bash
# uplink.sh start|stop|restart|status — manages the uplink process with a pidfile. Safe for the Ops Bot to call.
WS="${WORKSPACE:-/workspace/desk}"; PID="$WS/state/uplink/uplink.pid"; LOGD="$WS/logs"; mkdir -p "$WS/state/uplink" "$LOGD"
NODE="$(command -v node || echo "$WS/tools/node/bin/node")"
alive() { [ -f "$PID" ] && kill -0 "$(cat "$PID")" 2>/dev/null; }
case "${1:-status}" in
  start)
    if alive; then echo "uplink already running pid=$(cat "$PID")"; exit 0; fi
    [ -x "$NODE" ] || { echo "node not found; run bootstrap.sh"; exit 2; }
    setsid nohup "$NODE" "$WS/bin/uplink.mjs" >> "$LOGD/uplink.out" 2>&1 < /dev/null &
    sleep 2
    if alive; then echo "uplink started pid=$(cat "$PID")"; else echo "uplink failed to start; see $LOGD/uplink.out"; exit 1; fi ;;
  stop)
    if alive; then kill "$(cat "$PID")" && echo "uplink stopped"; else echo "uplink not running"; fi ;;
  restart)
    "$0" stop; sleep 1; "$0" start ;;
  status)
    if alive; then echo "uplink alive pid=$(cat "$PID")"; else echo "uplink DEAD"; exit 1; fi ;;
  *)
    echo "usage: uplink.sh start|stop|restart|status"; exit 1 ;;
esac
