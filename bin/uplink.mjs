#!/usr/bin/env node
// Uplink: the ONLY process on the Grok Bot cloud computer that talks HTTP to the engine.
// - every 10s: scan /workspace/desk/signals/<bot>/*.json, validate minimally, POST /signals (or /heartbeat, /reports), move to _delivered|_rejected|_expired
// - every 5min: pull /watchlist /positions /pnl /events /signals/stats into /workspace/desk/cache; every 30s: /requests into /workspace/desk/inbox/<bot>/ (+ acks)
// Config: /workspace/desk/config/engine.env (ENGINE_BASE_URL, ENGINE_TOKEN). Node >= 18 (global fetch). No dependencies.
import fs from 'node:fs';
import path from 'node:path';
import { spawn } from 'node:child_process';
import { fileURLToPath } from 'node:url';

const WS = process.env.WORKSPACE || '/workspace/desk';
const CFG = process.env.ENGINE_ENV || path.join(WS, 'config', 'engine.env');
const SIG = path.join(WS, 'signals');
const CACHE = path.join(WS, 'cache');
const INBOX = path.join(WS, 'inbox');
const STATE = path.join(WS, 'state', 'uplink');
const LOG = path.join(WS, 'logs', 'uplink.log');
const SCAN_MS = 10_000, PULL_MS = 300_000, REQ_PULL_MS = 30_000;   // requests every 30 s so a doorbell ring (45 s after the request) finds the file in the inbox
// Self-update: playbooks-sync.sh (run hourly by the Ops Bot) replaces this file on disk; a running process would keep
// the old code forever, so every pull compares the file's size+mtime with the one it started from and re-execs itself.
const SELF = fileURLToPath(import.meta.url);
const selfSig = () => { try { const s = fs.statSync(SELF); return `${s.size}:${Math.round(s.mtimeMs)}`; } catch { return ''; } };
const SELF_SIG = selfSig();
const MINT_RE = /^[1-9A-HJ-NP-Za-km-z]{32,44}$/;

for (const d of [SIG, CACHE, INBOX, STATE, path.dirname(LOG)]) fs.mkdirSync(d, { recursive: true });

function log(msg) {
  const line = `${new Date().toISOString()} ${msg}\n`;
  try { fs.appendFileSync(LOG, line); } catch {}
  process.stdout.write(line);
}
function loadEnv() {
  if (!fs.existsSync(CFG)) throw new Error(`missing ${CFG}`);
  const env = {};
  for (const l of fs.readFileSync(CFG, 'utf8').split(/\r?\n/)) {
    if (l.trim().startsWith('#')) continue;
    const m = l.match(/^\s*([A-Z_][A-Z0-9_]*)\s*=\s*(.*?)\s*$/);
    if (m) env[m[1]] = m[2].replace(/^["']|["']$/g, '');
  }
  if (!env.ENGINE_BASE_URL || !env.ENGINE_TOKEN) throw new Error('ENGINE_BASE_URL / ENGINE_TOKEN missing');
  return env;
}
const env = loadEnv();
const BASE = env.ENGINE_BASE_URL.replace(/\/+$/, '');
let backoffMs = 0, lastOk = 0, lastErr = '';

async function call(method, p, body, bot) {
  const ctrl = new AbortController(); const t = setTimeout(() => ctrl.abort(), 15_000);
  try {
    const res = await fetch(BASE + p, { method, headers: { 'content-type': 'application/json', authorization: `Bearer ${env.ENGINE_TOKEN}`, 'x-squad-bot': bot || 'uplink' }, body: body ? JSON.stringify(body) : undefined, signal: ctrl.signal });
    const text = await res.text(); let data; try { data = JSON.parse(text); } catch { data = { raw: text.slice(0, 300) }; }
    return { status: res.status, data };
  } finally { clearTimeout(t); }
}

function validate(sig) {
  const errs = [];
  if (sig.schema_version !== 1) errs.push('schema_version');
  for (const k of ['signal_id', 'bot', 'type', 'ts', 'ttl_sec']) if (sig[k] === undefined) errs.push(`missing ${k}`);
  if (sig.mint && !MINT_RE.test(sig.mint)) errs.push('mint format');
  if (['sentiment_score', 'contract_risk', 'narrative', 'kol_mention'].includes(sig.type)) {
    if (!Array.isArray(sig.reasons) || !sig.reasons.length) errs.push('reasons required');
    else if (sig.reasons.some((r) => !r.evidence_url)) errs.push('evidence_url required');
  }
  return errs;
}

function move(file, sub) {
  const bot = path.basename(path.dirname(file));
  const dir = path.join(SIG, sub, bot); fs.mkdirSync(dir, { recursive: true });
  fs.renameSync(file, path.join(dir, path.basename(file)));
}

function bodyFor(sig) {
  if (sig.type === 'heartbeat') return ['/heartbeat', sig];
  if (sig.type === 'digest') {
    let text = sig.body;
    if (!text && sig.path && fs.existsSync(String(sig.path))) text = fs.readFileSync(String(sig.path), 'utf8');
    return ['/reports', { bot: sig.bot, kind: 'digest', body: text || JSON.stringify(sig) }];
  }
  return ['/signals', sig];
}

async function scan() {
  if (backoffMs && Date.now() < backoffMs) return;
  let bots; try { bots = fs.readdirSync(SIG).filter((n) => !n.startsWith('_')); } catch { return; }
  for (const bot of bots) {
    const dir = path.join(SIG, bot); if (!fs.statSync(dir).isDirectory()) continue;
    for (const f of fs.readdirSync(dir).filter((n) => n.endsWith('.json')).sort()) {
      const file = path.join(dir, f); let sig;
      try { sig = JSON.parse(fs.readFileSync(file, 'utf8')); } catch { log(`reject ${f}: not json`); move(file, '_rejected'); continue; }
      const errs = validate(sig);
      if (errs.length) { log(`reject ${f}: ${errs.join(', ')}`); fs.writeFileSync(file + '.error', errs.join('\n')); move(file, '_rejected'); continue; }
      const exp = sig.expires_at ? Date.parse(sig.expires_at) : Date.parse(sig.ts) + sig.ttl_sec * 1000;
      if (exp < Date.now()) { move(file, '_expired'); continue; }
      const [p, body] = bodyFor(sig);
      try {
        const r = await call('POST', p, body, bot);
        if (r.status === 202 || r.status === 200) {
          move(file, '_delivered');
          fs.appendFileSync(path.join(STATE, 'delivered.log'), `${new Date().toISOString()} ${bot} ${sig.signal_id} ${r.data?.status || r.status}\n`);
          lastOk = Date.now(); backoffMs = 0;
        } else if (r.status === 422) {
          fs.writeFileSync(file + '.error', JSON.stringify(r.data)); move(file, '_rejected'); log(`422 ${f}: ${JSON.stringify(r.data).slice(0, 200)}`);
        } else if (r.status === 429) {
          log('429 rate limited; pausing 60s'); backoffMs = Date.now() + 60_000; return;
        } else { throw new Error(`HTTP ${r.status}`); }
      } catch (e) {
        lastErr = e.message;
        const prev = backoffMs ? Math.max(10_000, backoffMs - Date.now()) : 5_000;
        const wait = Math.min(300_000, prev * 2);
        backoffMs = Date.now() + wait; log(`engine unreachable (${e.message}); retry in ${Math.round(wait / 1000)}s`); return;
      }
    }
  }
}

async function pull() {
  await pullCache();
  await pullRequests();
  maybeReexecOnUpdate();
}

async function pullCache() {
  const targets = [['/watchlist', 'watchlist.json'], ['/positions', 'positions.json'], ['/pnl?range=7d', 'pnl.json'], ['/events', 'events_24h.json'], ['/signals/stats', 'signal_stats_7d.json']];
  for (const [p, name] of targets) {
    try {
      const r = await call('GET', p);
      if (r.status === 200) {
        const tmp = path.join(CACHE, name + '.tmp');
        fs.writeFileSync(tmp, JSON.stringify({ fetched_at: new Date().toISOString(), data: r.data }, null, 1));
        fs.renameSync(tmp, path.join(CACHE, name)); lastOk = Date.now();
      }
    } catch (e) { lastErr = e.message; log(`pull ${p} failed: ${e.message}`); }
  }
}

async function pullRequests() {
  // Chief (Phase 4) will own cache/narratives_seen.json; until then an empty file keeps Rug's copycat check from
  // reporting "narratives_seen.json: missing" on every run. Never overwritten once present.
  const seen = path.join(CACHE, 'narratives_seen.json');
  if (!fs.existsSync(seen)) { try { fs.writeFileSync(seen, JSON.stringify({ version: 1, updated_at: new Date().toISOString(), narratives: [] }, null, 1)); } catch {} }
  try {
    const r = await call('GET', '/requests?bot=*');
    if (r.status === 200 && Array.isArray(r.data)) for (const q of r.data) {
      const dir = path.join(INBOX, q.bot); fs.mkdirSync(dir, { recursive: true });
      // Any file starting with the request id (<id>.json, <id>.done, <id>.json.done, *.acked, *.unknown) means the Bot has or had it.
      if (fs.readdirSync(dir).some((n) => n.startsWith(q.request_id))) continue;
      fs.writeFileSync(path.join(dir, `${q.request_id}.json`), JSON.stringify(q, null, 1));
    }
    // Processed requests: the Bot renames <id>.json to <id>.done (tolerated: <id>.json.done). The id is read from the JSON
    // inside when possible; the engine answers 404 for an id it does not know (marked .unknown so it is never retried).
    for (const bot of fs.existsSync(INBOX) ? fs.readdirSync(INBOX) : []) {
      const dir = path.join(INBOX, bot);
      if (!fs.statSync(dir).isDirectory()) continue;
      for (const f of fs.readdirSync(dir).filter((n) => n.endsWith('.done'))) {
        const file = path.join(dir, f);
        let id = f.replace(/(\.json)?\.done$/, '');
        try { const j = JSON.parse(fs.readFileSync(file, 'utf8')); if (j && typeof j.request_id === 'string') id = j.request_id; } catch {}
        try {
          const a = await call('POST', `/requests/${encodeURIComponent(id)}/ack`, {}, bot);
          if (a.status === 200) { fs.renameSync(file, file + '.acked'); log(`ack ${bot} ${id}`); }
          else if (a.status === 404) { fs.renameSync(file, file + '.unknown'); log(`ack ${bot} ${id}: unknown to the engine`); }
          else log(`ack ${bot} ${id}: HTTP ${a.status}`);
        } catch (e) { log(`ack ${bot} ${id} failed: ${e.message}`); }
      }
    }
  } catch (e) { log(`requests pull failed: ${e.message}`); }
}

function maybeReexecOnUpdate() {
  const cur = selfSig();
  if (!cur || !SELF_SIG || cur === SELF_SIG) return;
  log(`uplink code changed on disk (${SELF_SIG} -> ${cur}); re-exec`);
  try {
    const out = fs.openSync(path.join(path.dirname(LOG), 'uplink.out'), 'a');
    spawn(process.execPath, [SELF], { detached: true, stdio: ['ignore', out, out], cwd: process.cwd(), env: process.env }).unref();
  } catch (e) { log(`re-exec failed: ${e.message}`); return; }
  process.exit(0);
}

function status() {
  let backlog = 0;
  try { for (const b of fs.readdirSync(SIG).filter((n) => !n.startsWith('_'))) backlog += fs.readdirSync(path.join(SIG, b)).filter((n) => n.endsWith('.json')).length; } catch {}
  fs.writeFileSync(path.join(STATE, 'status.json'), JSON.stringify({ ts: new Date().toISOString(), pid: process.pid, last_ok: lastOk ? new Date(lastOk).toISOString() : null, last_error: lastErr || null, backlog, backoff_until: backoffMs ? new Date(backoffMs).toISOString() : null }, null, 1));
}

log(`uplink start pid=${process.pid} engine=${BASE.replace(/^(https?:\/\/[^/]+).*$/, '$1')}`);
fs.writeFileSync(path.join(STATE, 'uplink.pid'), String(process.pid));
await pull(); await scan(); status();
setInterval(async () => { await scan(); status(); }, SCAN_MS);
setInterval(pull, PULL_MS);
setInterval(pullRequests, REQ_PULL_MS);
process.on('SIGTERM', () => { log('uplink stop'); process.exit(0); });
