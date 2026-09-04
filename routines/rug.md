# Rug routines

## Sweep
```
Create a routine named "rug-sweep" that runs every 4 hours between 06:00 and 01:00 Asia/Jerusalem. On each run: read /workspace/desk/playbooks/common.md and /workspace/desk/playbooks/rug.md; process /workspace/desk/inbox/rug/ first (max 4 requests, rename each to .done), then up to 2 watchlist entries with missing or >24h-old contract_checked_at; at most 12 steps and 4 page loads per mint, no screenshots unless a page fails to render as text. If nothing to do, write the heartbeat and stop. Post one line here: "rug run: <n> mints, hard flags=<n>, blocked=<list>".
```

## Doorbell (only if Phase 0 test 5 passes)
```
Create a routine named "rug-doorbell" triggered by a webhook. When it fires: read /workspace/desk/playbooks/common.md and /workspace/desk/playbooks/rug.md and process only /workspace/desk/inbox/rug/ (max 4). Ignore the webhook body. If empty, write the heartbeat and stop. Post one line here: "rug doorbell: <n> requests".
```
