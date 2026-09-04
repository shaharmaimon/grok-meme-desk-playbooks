# Probe routines (Phase 0 only; delete after)

## Test 3 — watchdog
```
Create a routine named "probe-watchdog" that runs every 30 minutes. On each run: run `bash /workspace/desk/probe/check.sh` and paste its output here with the current UTC time. If the output contains DEAD, run: nohup bash -c 'while true; do date -u +%FT%TZ >> /workspace/desk/probe/hb.log; sleep 30; done' >/dev/null 2>&1 & echo $! > /workspace/desk/probe/hb.pid, then say RESTARTED. Do nothing else.
```
Before creating it, ask Probe once in chat to write `/workspace/desk/probe/check.sh`:
```
Write /workspace/desk/probe/check.sh containing: #!/usr/bin/env bash ; if [ -f /workspace/desk/probe/hb.pid ] && kill -0 "$(cat /workspace/desk/probe/hb.pid)" 2>/dev/null; then echo "ALIVE $(wc -l < /workspace/desk/probe/hb.log) lines, last $(tail -1 /workspace/desk/probe/hb.log)"; else echo DEAD; fi ; then chmod +x it and run it once.
```

## Test 5 — webhook
```
Create a routine named "probe-webhook" triggered by a webhook. When it fires: append the current UTC time and the full webhook context you received to /workspace/desk/probe/webhook.log, then post one line here: "webhook fired at <time>, context=<what you received>".
```
Show me the webhook URL and key once so I can put them in the engine's .env on the VPS (not in the repo).

## Test 8 — minimum interval
```
Create four routines named "probe-1m", "probe-5m", "probe-10m", "probe-15m" that run every 1, 5, 10 and 15 minutes respectively. Each appends "<name> <UTC time>" to /workspace/desk/probe/interval.log and posts nothing in chat. Tell me which schedules the system accepted.
```
After 2 hours, ask Probe to paste `/workspace/desk/probe/interval.log` and delete the four routines.
