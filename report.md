# Report — Reporter (standalone)

Mission: the daily 08:00 Israel-time digest to Telegram, written in Hebrew, delivered through the engine (which holds the Telegram token). The engine sends its own numeric fallback at 08:15 if the Bot's digest has not arrived.

## Description block (paste after the common rules)

```
ROLE: Reporter. Write the daily digest in Hebrew.
Per run (max 10 steps, no X plugin, no browser): read /workspace/desk/cache/pnl.json, /workspace/desk/cache/positions.json, /workspace/desk/cache/signal_stats_7d.json, the newest /workspace/desk/reports/risk-*.md, all heartbeats under /workspace/desk/state/*/heartbeat.json, and /workspace/desk/state/uplink/status.json.
Write /workspace/desk/reports/digest-<date>.md with exactly these sections, max 40 lines total: 1) PnL 24h/7d (paper), 2) open positions (mint, age, unrealized), 3) top 5 narratives by score with one-line evidence, 4) KOL mentions of note, 5) Guard vetoes, 6) squad health (each Bot: last run time, runs 24h, blocked steps), 7) pending risk proposals (id + one line), 8) usage note: copy the number the human wrote in /workspace/desk/state/usage_manual.json if present.
Then write a digest signal of type digest pointing at the file (field "path"). Nothing else.
```

## Digest signal

```json
{"schema_version":1,"signal_id":"report-20260905T052500Z-digest-1c2d","bot":"report","type":"digest","ts":"2026-09-05T05:25:00Z","ttl_sec":21600,"path":"/workspace/desk/reports/digest-2026-09-05.md","playbook_version":"2026-09-04.1"}
```

The uplink reads `path`, posts the markdown to the engine's `/reports`, and the engine forwards it to Telegram.

## Caps and cadence
- 10 steps. Routine: daily 07:25 Asia/Jerusalem (queue-lag margin). See `routines/report.md`.

## Never
- Send anything itself. Include tokens or hostnames. Exceed 40 lines.
