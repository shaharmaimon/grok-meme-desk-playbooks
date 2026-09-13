#!/usr/bin/env bash
# uplink-supervisor.sh — keeps uplink.mjs running without a Bot in the loop (2026-09-08).
#
# Until now only the Ops Bot restarted a dead uplink, and the Ops Bot only runs when Grok's routine scheduler fires
# (it silently skipped three runs today). This loop is started once by `uplink.sh start` (setsid + nohup, survives
# the Bot's turn ending and the app closing — Phase 0 test) and restarts the uplink 5 s after any exit:
#   - a crash → restart; the log line says so;
#   - a code update (playbooks-sync.sh replaced uplink.mjs) → the uplink exits 75 (UPLINK_SUPERVISED=1) and the
#     loop starts the new code — no detached re-exec, so there is never a second copy;
#   - `uplink.sh stop` drops the STOP flag and kills the child → the loop exits cleanly.
# Not covered: "Update Agent Computer" kills everything; the Ops Bot's `uplink.sh start` (or bootstrap) brings it back.
WS="${WORKSPACE:-/workspace/desk}"; STATE="$WS/state/uplink"; LOGD="$WS/logs"; mkdir -p "$STATE" "$LOGD"
STOP="$STATE/STOP"; SUP_PID="$STATE/supervisor.pid"
NODE="$(command -v node || echo "$WS/tools/node/bin/node")"
if [ -f "$SUP_PID" ] && [ "$(cat "$SUP_PID" 2>/dev/null)" != "$$" ] && kill -0 "$(cat "$SUP_PID")" 2>/dev/null; then echo "supervisor already running pid=$(cat "$SUP_PID")"; exit 0; fi
echo $$ > "$SUP_PID"
rm -f "$STOP"
export UPLINK_SUPERVISED=1
stamp() { date -u +%Y-%m-%dT%H:%M:%S.000Z; }
echo "$(stamp) supervisor start pid=$$" >> "$LOGD/uplink.log"
n=0
while :; do
  "$NODE" "$WS/bin/uplink.mjs"; rc=$?
  if [ -f "$STOP" ]; then echo "$(stamp) supervisor: stop requested (uplink exit $rc)" >> "$LOGD/uplink.log"; break; fi
  n=$((n + 1))
  if [ "$rc" = "75" ]; then echo "$(stamp) supervisor: uplink asked for a restart (new code), restart #$n" >> "$LOGD/uplink.log"; sleep 1
  else echo "$(stamp) supervisor: uplink exited rc=$rc, restart #$n in 5 s" >> "$LOGD/uplink.log"; sleep 5; fi
done
rm -f "$SUP_PID"
