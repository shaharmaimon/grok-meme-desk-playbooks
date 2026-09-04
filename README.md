# grok-meme-desk playbooks

Instruction files, signal schema and helper scripts for a research squad of xAI Grok Bot agents that analyse Solana memecoins for a **paper-trading** engine. This repository is public on purpose so the squad's shared cloud computer can pull it without any credential; it contains no secrets, no keys and no engine code.

- `common.md` — rules every Bot follows (analysis only; never trades, never holds keys, never spends).
- `<bot>.md` — one playbook per role: scout, kol, sent, rug, chief, risk, report, ops.
- `routines/` — the exact routine-creation prompts per Bot.
- `schema/signal.schema.json` — the JSON contract for every signal the squad emits.
- `bin/` — box-side scripts: `bootstrap.sh`, `uplink.mjs` + `uplink.sh`, `ops-check.sh`, `playbooks-sync.sh`, `engine.sh`, `cleanup-bot.sh`.

Bootstrap on the cloud computer:

```bash
git clone --depth 1 https://github.com/shaharmaimon/grok-meme-desk-playbooks.git /workspace/desk/_repo
bash /workspace/desk/_repo/bin/bootstrap.sh
```

Nothing here is financial advice. The engine that consumes these signals trades the operator's own funds in paper mode by default.
