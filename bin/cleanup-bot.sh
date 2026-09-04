#!/usr/bin/env bash
# cleanup-bot.sh <bot> — archive a deleted/rotated Bot's signals and state (files survive Bot deletion on the shared computer).
WS="${WORKSPACE:-/workspace/desk}"; B="${1:?bot name}"; TS=$(date -u +%Y%m%dT%H%M%SZ); A="$WS/_archive/$B-$TS"; mkdir -p "$A"
for d in signals state inbox; do [ -d "$WS/$d/$B" ] && mv "$WS/$d/$B" "$A/$d"; done
mkdir -p "$WS/signals/$B" "$WS/state/$B" "$WS/inbox/$B"; echo "archived to $A"
