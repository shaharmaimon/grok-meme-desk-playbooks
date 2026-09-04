#!/usr/bin/env bash
# bootstrap.sh — one-time (and after a Reset) setup of /workspace on the Grok Bot cloud computer.
# Usage: bash bootstrap.sh <git-repo-url>
set -e
WS="${WORKSPACE:-/workspace/desk}"; REPO="${1:-}"
mkdir -p "$WS"/{cache,inbox,signals,state/uplink,state/ops,reports,logs,config,tools}
if [ ! -e "$WS/playbooks" ]; then
  [ -n "$REPO" ] || { echo "usage: bootstrap.sh <git-repo-url>"; exit 1; }
  git clone --depth 1 "$REPO" "$WS/_repo"
  # The repo may be the full project (playbooks under squad/playbooks) or a playbooks-only repo (root is the playbooks folder).
  if [ -d "$WS/_repo/squad/playbooks" ]; then ln -sfn "$WS/_repo/squad/playbooks" "$WS/playbooks"; else ln -sfn "$WS/_repo" "$WS/playbooks"; fi
fi
ln -sfn "$WS/playbooks/bin" "$WS/bin"
chmod +x "$WS"/playbooks/bin/*.sh "$WS"/playbooks/bin/*.mjs 2>/dev/null || true
for b in scout kol sent rug chief risk report ops probe; do mkdir -p "$WS/signals/$b" "$WS/state/$b" "$WS/inbox/$b"; done
if ! command -v node >/dev/null 2>&1 && [ ! -x "$WS/tools/node/bin/node" ]; then
  echo "node not found. Download a static Node tarball into $WS/tools/node (survives image updates), e.g.:"
  echo "  curl -fsSL https://nodejs.org/dist/v22.17.0/node-v22.17.0-linux-x64.tar.xz | tar -xJ -C $WS/tools && mv $WS/tools/node-v22.17.0-linux-x64 $WS/tools/node"
fi
if [ ! -f "$WS/config/engine.env" ]; then
  printf '# WARNING: shared computer; every Bot can read this file. Signals-only token; rotate monthly.\n# ENGINE_BASE_URL=https://engine.example.com\n# ENGINE_TOKEN=\n' > "$WS/config/engine.env"
fi
chmod 600 "$WS/config/engine.env" || true
echo "bootstrap done. Fill $WS/config/engine.env yourself in the terminal (never via chat), then: bash $WS/bin/uplink.sh start"
