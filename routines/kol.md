# Kol routines

## Lean
```
Create a routine named "kol-watch" that runs every 3 hours between 06:00 and 01:00 Asia/Jerusalem. On each run: read /workspace/desk/playbooks/common.md and /workspace/desk/playbooks/kol.md, load /workspace/desk/playbooks/kol_list.json and /workspace/desk/state/kol/cursor.json, and execute the run procedure with at most 10 X plugin calls and 15 steps. Update the cursor file at the end. If no new posts, still write the heartbeat. Post one line here: "kol run: <n> mentions, <n> X calls, blocked=<list>".
```

## Standard
```
Update the routine "kol-watch" to run every 90 minutes between 06:00 and 01:00 Asia/Jerusalem.
```
