# Hermes (Nous Research) → OpenLid hook

This makes Hermes report **Working / Idle** to OpenLid with real per-session accuracy,
using Hermes' built-in [shell hooks](https://hermes-agent.nousresearch.com/docs/).

By default OpenLid also detects Hermes via **process detection** (the `hermes` process),
so Hermes lights up as "running" even without this hook installed. Install the hook for
accurate per-session Working/Idle instead of coarse "process alive".

## Install

1. Copy the script somewhere stable and make it executable:

   ```sh
   mkdir -p ~/.openlid/hooks/hermes
   cp openlid-hook.sh ~/.openlid/hooks/hermes/
   chmod +x ~/.openlid/hooks/hermes/openlid-hook.sh
   ```

2. Add the hooks to your Hermes config (`~/.hermes/config.yaml`). Merge this into the
   existing `hooks:` block (it ships empty, `hooks: {}`). **Use the absolute path**
   (replace `<YOU>` with your username) — Hermes runs the command via `shlex.split`
   with `shell=False`, so `~` is **not** expanded:

   ```yaml
   hooks:
     on_session_start:
       - command: "/Users/<YOU>/.openlid/hooks/hermes/openlid-hook.sh working"
     pre_tool_call:
       - command: "/Users/<YOU>/.openlid/hooks/hermes/openlid-hook.sh working"
     on_session_end:
       - command: "/Users/<YOU>/.openlid/hooks/hermes/openlid-hook.sh idle"

   hooks_auto_accept: true   # optional; see "Consent" below
   ```

That's it. When a Hermes session starts or runs a tool, OpenLid sees "working"; when the
session ends, the status file is removed and the idle timeout begins.

## Consent

The first time Hermes sees a new `(event, command)` pair it prompts you to approve it,
then persists the decision to `~/.hermes/shell-hooks-allowlist.json`. For non-interactive
runs (the gateway, cron, CI) approve up front with any one of:

- `hooks_auto_accept: true` in `~/.hermes/config.yaml`
- `HERMES_ACCEPT_HOOKS=1` in the environment
- the `--accept-hooks` CLI flag (e.g. `hermes --accept-hooks chat`)

Verify the wiring any time with `hermes hooks list` and `hermes hooks doctor`.

## How it works

Hermes pipes a JSON payload on stdin for every hook event; the script reads `session_id`
from it and writes `~/.openlid/agents/hermes-<session>.json` containing
`{"agent":"hermes","status":"working"}` while working, deleting it on `on_session_end`.
It prints `{}` on stdout, which Hermes treats as a no-op response. OpenLid also treats any
file untouched for ~6 hours as stale, so a crashed session never holds your Mac awake
forever. See [../README.md](../README.md) for the shared file contract.
