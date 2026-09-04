#!/usr/bin/env bash
# playbooks-sync.sh — git pull the playbooks repo and check the signal schema parses. Records the sha for ops-check.
WS="${WORKSPACE:-/workspace/desk}"; cd "$WS/playbooks" || { echo "no playbooks dir; run bootstrap.sh"; exit 2; }
git pull --ff-only -q && echo "playbooks updated to $(git rev-parse --short HEAD)" || { echo "git pull failed"; exit 1; }
NODE="$(command -v node || echo "$WS/tools/node/bin/node")"
[ -x "$NODE" ] && "$NODE" -e 'JSON.parse(require("fs").readFileSync(process.argv[1],"utf8")); console.log("schema ok")' "$WS/playbooks/schema/signal.schema.json"
mkdir -p "$WS/state/ops"; git rev-parse --short HEAD > "$WS/state/ops/last_playbook_sha"
