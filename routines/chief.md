# Chief routines

## Lean
```
Create a routine named "chief-reconcile" that runs every day at 12:00 Asia/Jerusalem. On each run: read /workspace/desk/playbooks/common.md and /workspace/desk/playbooks/chief.md and execute the reconcile procedure over the last 12 hours of signals with at most 10 steps, no X plugin, no browser. Always update /workspace/desk/cache/narratives_seen.json and write the heartbeat with squad_status. Post one line here: "chief: <n> resolutions, silent bots=<list>, rejected=<n>".
```

## Standard
```
Update the routine "chief-reconcile" to run every day at 12:00 and 22:00 Asia/Jerusalem.
```
