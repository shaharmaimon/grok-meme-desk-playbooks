# Ops — Ops Watchdog (standalone)

Mission: keep the box-side plumbing alive: uplink process, outbox backlog, disk, cache freshness, playbook sync; restart what it is allowed to restart; write a heartbeat the engine can alarm on. Phase 0 proved that "Update Agent Computer" reboots the box (all background processes die, empty directories vanish, files survive), so this Bot is the only thing that brings the uplink back.

## Description block (paste after the common rules)

```
ROLE: Ops Watchdog. Every run (max 6 steps, no X plugin, no browser):
1. Run: bash /workspace/desk/bin/ops-check.sh   (prints one JSON line: uplink_alive, outbox_count, oldest_outbox_age_s, cache_age_s, disk_free_mb, playbook_sha, last_playbook_sha, topology, engine_health_cached, uplink_last_error, uplink_last_ok_age_s)
2. If uplink_alive is false: run bash /workspace/desk/bin/uplink.sh restart, then re-run ops-check.sh once.
3. If playbook_sha differs from last_playbook_sha: run bash /workspace/desk/bin/playbooks-sync.sh and record the result.
4. If topology is "local" and engine_health_cached is false: run bash /workspace/desk/bin/engine.sh restart once.
5. Write /workspace/desk/state/ops/heartbeat.json with all values and the actions taken, and drop a heartbeat signal in /workspace/desk/signals/ops/. Do not run any other command. Never edit these scripts.
```

## Auto Review rules for this Bot
- Always Allow exactly: `bash /workspace/desk/bin/ops-check.sh`, `bash /workspace/desk/bin/uplink.sh restart`, `bash /workspace/desk/bin/playbooks-sync.sh`, `bash /workspace/desk/bin/engine.sh restart`.
- Require Approval on everything else in the shell (`curl`, `wget`, `ssh`, `scp`, `nc`, `rm -rf`, package installs).

## Heartbeat example

```json
{"schema_version":1,"signal_id":"ops-20260904T100000Z-hb-0a1b","bot":"ops","type":"heartbeat","ts":"2026-09-04T10:00:00Z","ttl_sec":3600,"status":"ok","run_id":"ops-20260904T1000","steps_used":2,"signals_written":1,"blocked_steps":[],"notes":"uplink alive; outbox 0; cache 240s","ops":{"uplink_alive":true,"outbox_count":0,"cache_age_s":240,"disk_free_mb":18200,"actions":[]}}
```

## Caps and cadence
- 6 steps. Routine: every 30 min (Standard), hourly (Lean). This is the single largest fixed usage cost; keep it hourly until Phase 0 measures per-run cost. See `routines/ops.md`.

## Never
- Install packages. Edit scripts. Reset the computer. Touch `/workspace/desk/config`.

## Token rotation

The squad bearer (`SIGNALS_TOKEN` in the VPS `.env`) is a single secret shared by the engine and the box's uplink. Rotating it never needs a manual uplink restart on the box anymore: the engine accepts the old token alongside the new one while `SIGNALS_TOKEN_PREV` is set, and `uplink.mjs` re-reads `engine.env` when the file changes or on the first `401`. Everything below runs from the human's shell; the Ops Bot is not involved beyond its normal heartbeat.

Operator steps (the whole window should close within 24 h):

1. **Rotate (VPS, as root):** `bash /opt/memebot/engine/scripts/vps/rotate-signals-token.sh` — mints a new token with `openssl rand -hex 32`, parks the current one in `SIGNALS_TOKEN_PREV` (atomic `.env` rewrite, `600`, backup `.env.bak-<ts>`), restarts `memebot`, waits for `/health`, mints a one-time bootstrap code and prints **only** the bootstrap URL on stdout (progress is on stderr; no token is ever printed). `/health` now shows `token_prev_configured: true`.
2. **Hand the URL to the box:** send Probe the one-time URL with the same curl as `squad/app-paste/probe.uplink.txt` step 1 (`mkdir -p /workspace/desk/config && curl -fsS -m 20 "<URL>" -o /workspace/desk/config/engine.env && chmod 600 ... && wc -l ...`). The link is single-use and expires in 10 min; the file it returns carries the NEW token only.
3. **Let the uplink pick it up:** the running uplink notices the changed `engine.env` on its next scan (≤ 10 s) and switches tokens by itself. If it was already refusing (`status.json` `last_error: "auth_401"`, backoff ≤ 60 s) the reload happens on that same scan. A belt-and-braces `bash /workspace/desk/bin/uplink.sh restart` (Ops's allow-listed command) is fine but not required.
4. **Verify on the engine:** `bash /opt/memebot/engine/scripts/vps/rotate-signals-token.sh status` prints (stderr, no secrets) exactly three lines: `token_prev_configured=… token_prev_since=… auth_prev_used_24h=… auth_prev_last_used=…`, then `uplink_last_seen=… squad_last_seen={…}`, then `env: rotation window OPEN (…)` / `env: no rotation window` (whether the `.env` still carries `SIGNALS_TOKEN_PREV`). It reads `/health` on `200` and on `503` (halted / pipeline down) alike; when the engine does not answer at all the first two lines are replaced by `health unavailable: …` and the command exits 1. What proves the switch: **`auth_prev_last_used`** (last request the OLD token authenticated) stops moving and is older than 15 min, and `auth_prev_used_24h` stops growing (every request still on the old token adds to it; the engine also logs one `token_prev_used` event per 10 min while that happens). `uplink_last_seen` and `squad_last_seen` should keep advancing, but they count requests on EITHER token, so on their own they do not prove anything. Raw: `curl -s 127.0.0.1:8787/health` carries the same fields.
5. **Finish (within 24 h):** `bash /opt/memebot/engine/scripts/vps/rotate-signals-token.sh finish` — prints `auth_prev_used_24h` / `auth_prev_last_used` one last time, removes `SIGNALS_TOKEN_PREV`, restarts, and the old token gets `401`. Until this runs, every engine boot older than 24 h into the window sends a Hebrew `warn` to Telegram ("רוטציית טוקן לא הושלמה") that reads the same `auth_prev_last_used` stamp and says which step applies: no old-token use for 15 min → run `finish`; a recent use → the uplink is still on the old token, send the box a fresh bootstrap file (`rotate --force`). `--force` on `rotate` starts a new window while one is open (the oldest token is dropped).

Where it shows up on the box side: `ops-check.sh` adds `uplink_last_error` (`auth_401` = the engine refuses the token → the box needs the new bootstrap file) and `uplink_last_ok_age_s` (seconds since the last accepted call, `-1` = never) to the heartbeat JSON line, so a rotation that stalled is visible in `state/ops/heartbeat.json` and in the engine's ops heartbeat signal without reading any log.

Never: paste the token itself into chat, a Bot description, or a signal; the one-time URL is the only thing that crosses to the box.
