#!/usr/bin/env bash
# ops-check.sh — prints one JSON line the Ops Bot copies into its heartbeat. Read-only apart from log rotation.
WS="${WORKSPACE:-/workspace/desk}"
# "Update Agent Computer" reboots the box and drops EMPTY directories; recreate the layout on every run.
mkdir -p "$WS"/{cache,inbox,signals,state/uplink,state/ops,reports,logs,config,tools}
alive=false; [ -f "$WS/state/uplink/uplink.pid" ] && kill -0 "$(cat "$WS/state/uplink/uplink.pid")" 2>/dev/null && alive=true
outbox=0; oldest=0; now=$(date +%s)
for d in "$WS"/signals/*/; do n=$(basename "$d"); case "$n" in _*) continue;; esac
  for f in "$d"*.json; do [ -f "$f" ] || continue; outbox=$((outbox+1)); m=$(stat -c %Y "$f" 2>/dev/null || echo "$now"); a=$((now-m)); [ "$a" -gt "$oldest" ] && oldest=$a; done; done
cache_age=-1; [ -f "$WS/cache/watchlist.json" ] && cache_age=$((now-$(stat -c %Y "$WS/cache/watchlist.json")))
disk=$(df -Pm "$WS" 2>/dev/null | awk 'NR==2{print $4}')
sha=$(cd "$WS/playbooks" 2>/dev/null && git rev-parse --short HEAD 2>/dev/null || echo "none")
last_sha=$(cat "$WS/state/ops/last_playbook_sha" 2>/dev/null || echo "none")
topo=$(cat "$WS/config/topology.txt" 2>/dev/null || echo "remote")
eng=null; [ -f "$WS/cache/watchlist.json" ] && eng=$([ "$cache_age" -lt 900 ] && echo true || echo false)
# uplink status.json (written by uplink.mjs, one key per line): last_error ("auth_401" = the engine rejects the token → a
# rotation needs the new bootstrap file, see ops.md "Token rotation") and the age of the last accepted call.
st="$WS/state/uplink/status.json"; ul_err=null; ul_ok_age=-1
if [ -f "$st" ]; then
  e=$(sed -n 's/^ *"last_error": *"\([^"]*\)".*/\1/p' "$st" | head -1 | tr -d '\\' | cut -c1-80)
  [ -n "$e" ] && ul_err="\"$e\""
  ok=$(sed -n 's/^ *"last_ok": *"\([^"]*\)".*/\1/p' "$st" | head -1)
  if [ -n "$ok" ]; then oks=$(date -d "$ok" +%s 2>/dev/null || echo ""); [ -n "$oks" ] && ul_ok_age=$((now-oks)); fi
fi
for l in "$WS"/logs/*.log "$WS"/logs/*.out; do [ -f "$l" ] && [ "$(stat -c %s "$l")" -gt 20000000 ] && mv "$l" "$l.1"; done
printf '{"ts":"%s","uplink_alive":%s,"outbox_count":%d,"oldest_outbox_age_s":%d,"cache_age_s":%d,"disk_free_mb":%s,"playbook_sha":"%s","last_playbook_sha":"%s","topology":"%s","engine_health_cached":%s,"uplink_last_error":%s,"uplink_last_ok_age_s":%d}\n' \
  "$(date -u +%FT%TZ)" "$alive" "$outbox" "$oldest" "$cache_age" "${disk:-0}" "$sha" "$last_sha" "$topo" "$eng" "$ul_err" "$ul_ok_age"
