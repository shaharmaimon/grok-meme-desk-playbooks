# Sent routines

## Sweep (Lean and Standard)
```
Create a routine named "sent-sweep" that runs every 3 hours between 06:00 and 01:00 Asia/Jerusalem. On each run: read /workspace/desk/playbooks/common.md and /workspace/desk/playbooks/sent.md; process /workspace/desk/inbox/sent/ first (max 5 requests, rename each to .done), then up to 5 watchlist entries with the oldest sentiment_checked_at; at most 3 X plugin calls per mint and 15 steps total. If nothing to do, write the heartbeat and stop. Post one line here: "sent run: <n> mints scored, blocked=<list>".
```

## Doorbell (only if Phase 0 test 5 passes)
```
Create a routine named "sent-doorbell" triggered by a webhook. When it fires: read /workspace/desk/playbooks/common.md and /workspace/desk/playbooks/sent.md, process only the files in /workspace/desk/inbox/sent/ (max 5), ignore the webhook body. If the inbox is empty, write the heartbeat and stop. Post one line here: "sent doorbell: <n> requests".
```
Record the webhook URL and key in the engine's `.env` (never in the repo, never in a Bot).
