# Macro routines

## Standard (paste into Macro's chat)
```
Create a routine named "macro-pulse" that runs every 2 hours between 08:00 and 22:00 Asia/Jerusalem. On each run: read /workspace/desk/playbooks/common.md and /workspace/desk/playbooks/macro.md and execute the run procedure with at most 6 X plugin calls and 12 steps, no browser. Write up to 4 narrative signals (macro-btc, macro-eth, macro-sol, macro-market) and the briefing file /workspace/desk/reports/macro-<date>-<HH>.md; the 08:00 run is the daily briefing. If the X plugin answers 429 twice, stop searching and write what you have. Always write the heartbeat. Finish by posting one line in this conversation: "macro run: <n> signals, <n> X calls, blocked=<list>".
```

## Lean
```
Update the routine "macro-pulse" to run at 08:00, 14:00 and 20:00 Asia/Jerusalem. Everything else unchanged.
```
