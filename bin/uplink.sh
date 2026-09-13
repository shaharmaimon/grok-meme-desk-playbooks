#!/usr/bin/env bash
# uplink.sh start|stop|restart|status — manages the uplink through its supervisor loop (uplink-supervisor.sh), with
# pidfiles for both. Safe for the Ops Bot to call. `start` is idempotent; `stop` takes the supervisor down with the
# child so nothing restarts behind our back; `status` exits 1 when the uplink itself is dead.
WS="${WORKSPACE:-/workspace/desk}"; STATE="$WS/state/uplink"; PID="$STATE/uplink.pid"; SUP_PID="$STATE/supervisor.pid"; STOP="$STATE/STOP"; LOGD="$WS/logs"
mkdir -p "$STATE" "$LOGD"
NODE="$(command -v node || echo "$WS/tools/node/bin/node")"
alive() { [ -f "$PID" ] && kill -0 "$(cat "$PID")" 2>/dev/null; }
sup_alive() { [ -f "$SUP_PID" ] && kill -0 "$(cat "$SUP_PID")" 2>/dev/null; }
case "${1:-status}" in
  start)
    exec 9>"$STATE/start.lock"; flock -n 9 || { echo "another start is in progress"; exit 0; }
    if sup_alive; then
      if alive; then echo "uplink already running pid=$(cat "$PID") (supervisor $(cat "$SUP_PID"))"; else echo "supervisor alive pid=$(cat "$SUP_PID"), uplink restarting"; fi
      exit 0
    fi
    if alive; then
      # an uplink started the old way (no supervisor): keep it, but note it — the next restart adopts the supervisor
      echo "uplink already running pid=$(cat "$PID") without a supervisor; run 'uplink.sh restart' to adopt one"; exit 0
    fi
    [ -x "$NODE" ] || { echo "node not found; run bootstrap.sh"; exit 2; }
    rm -f "$STOP"
    setsid nohup bash "$WS/bin/uplink-supervisor.sh" >> "$LOGD/uplink.out" 2>&1 < /dev/null &
    sleep 3
    if alive; then echo "uplink started pid=$(cat "$PID") (supervisor $(cat "$SUP_PID" 2>/dev/null))"; else echo "uplink failed to start; see $LOGD/uplink.out"; exit 1; fi ;;
  stop)
    touch "$STOP"
    stopped=false
    if alive; then kill "$(cat "$PID")" 2>/dev/null && stopped=true; fi
    sleep 1
    if sup_alive; then kill "$(cat "$SUP_PID")" 2>/dev/null; fi
    sleep 1
    rm -f "$STOP" "$SUP_PID"
    if $stopped; then echo "uplink stopped"; else echo "uplink not running"; fi ;;
  restart)
    "$0" stop; sleep 1; "$0" start ;;
  status)
    if alive; then echo "uplink alive pid=$(cat "$PID") supervisor=$(sup_alive && echo alive || echo none)"; else echo "uplink DEAD supervisor=$(sup_alive && echo alive || echo none)"; exit 1; fi ;;
  *)
    echo "usage: uplink.sh start|stop|restart|status"; exit 1 ;;
esac
