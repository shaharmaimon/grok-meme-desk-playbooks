#!/usr/bin/env bash
# playbooks-sync.sh — git pull the playbooks repo and check the signal schema parses. Records the sha for ops-check.
WS="${WORKSPACE:-/workspace/desk}"; cd "$WS/playbooks" || { echo "no playbooks dir; run bootstrap.sh"; exit 2; }
# The box never edits playbooks: ignore chmod-only diffs (bootstrap marks scripts executable) and track origin/main exactly.
git config core.fileMode false
git fetch -q origin main && git reset -q --hard origin/main && echo "playbooks updated to $(git rev-parse --short HEAD)" || { echo "git sync failed"; exit 1; }
chmod +x "$WS"/playbooks/bin/*.sh "$WS"/playbooks/bin/*.mjs 2>/dev/null || true
NODE="$(command -v node || echo "$WS/tools/node/bin/node")"
[ -x "$NODE" ] && "$NODE" -e 'JSON.parse(require("fs").readFileSync(process.argv[1],"utf8")); console.log("schema ok")' "$WS/playbooks/schema/signal.schema.json"
mkdir -p "$WS/state/ops"; git rev-parse --short HEAD > "$WS/state/ops/last_playbook_sha"
