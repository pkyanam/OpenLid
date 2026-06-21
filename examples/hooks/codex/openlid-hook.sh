#!/usr/bin/env bash
#
# OpenLid hook for OpenAI Codex CLI.
#
# Usage:  openlid-hook.sh <working|idle> [session-id]
#
# Writes a status file into ~/.openlid/agents/ that OpenLid watches. If your Codex
# integration passes event JSON on stdin, we try to read `session_id` from it.
#
set -euo pipefail

STATE="${1:-working}"
SESSION="${2:-}"
AGENT="codex"
DIR="$HOME/.openlid/agents"
mkdir -p "$DIR"

if [ -z "$SESSION" ]; then
  INPUT="$(cat 2>/dev/null || true)"
  if command -v python3 >/dev/null 2>&1; then
    SESSION="$(printf '%s' "$INPUT" | python3 -c 'import sys, json
try:
    print(json.load(sys.stdin).get("session_id", ""))
except Exception:
    print("")' 2>/dev/null || true)"
  fi
fi
[ -z "$SESSION" ] && SESSION="default"

FILE="$DIR/${AGENT}-${SESSION}.json"

case "$STATE" in
  idle|stop)
    rm -f "$FILE"
    ;;
  *)
    printf '{"agent":"%s","status":"working","session":"%s"}\n' "$AGENT" "$SESSION" > "$FILE"
    ;;
esac
