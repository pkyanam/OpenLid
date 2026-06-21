#!/usr/bin/env bash
#
# OpenLid hook for Claude Code.
#
# Usage:  openlid-hook.sh <working|idle>
#
# Claude Code passes hook event JSON on stdin; we read `session_id` from it so each
# Claude session is tracked independently. The script writes a status file into
# ~/.openlid/agents/ that OpenLid watches.
#
set -euo pipefail

STATE="${1:-working}"
AGENT="claude-code"
DIR="$HOME/.openlid/agents"
mkdir -p "$DIR"

INPUT="$(cat 2>/dev/null || true)"

SESSION=""
if command -v python3 >/dev/null 2>&1; then
  SESSION="$(printf '%s' "$INPUT" | python3 -c 'import sys, json
try:
    print(json.load(sys.stdin).get("session_id", ""))
except Exception:
    print("")' 2>/dev/null || true)"
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
