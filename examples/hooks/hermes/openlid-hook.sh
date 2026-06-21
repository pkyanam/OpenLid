#!/usr/bin/env bash
#
# OpenLid hook for Hermes (Nous Research).
#
# Usage:  openlid-hook.sh <working|idle>
#
# Hermes shell hooks pipe a JSON payload on stdin (see the Hermes "Shell Hooks"
# docs); we read `session_id` from it so each Hermes session is tracked
# independently. The script writes a status file into ~/.openlid/agents/ that
# OpenLid watches, then prints `{}` on stdout (Hermes expects a JSON response).
#
set -euo pipefail

STATE="${1:-working}"
AGENT="hermes"
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

# Hermes reads stdout as an optional JSON response; an empty object is a no-op.
printf '{}\n'
