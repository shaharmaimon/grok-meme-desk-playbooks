# Scout routines

## Lean (paste into Scout's chat)
```
Create a routine named "scout-sweep" that runs every day at 08:00, 14:00 and 21:00 Asia/Jerusalem. On each run: read /workspace/desk/playbooks/common.md and /workspace/desk/playbooks/scout.md and execute the run procedure with at most 8 X plugin calls and 15 steps. If nothing qualifies, still write the heartbeat. Finish by posting one line in this conversation: "scout run: <n> signals, <n> X calls, blocked=<list>".
```

## Standard
```
Update the routine "scout-sweep" to run every 2 hours between 06:00 and 01:00 Asia/Jerusalem. Everything else unchanged.
```
