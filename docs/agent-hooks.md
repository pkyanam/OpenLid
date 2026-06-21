# Agent Hooks

Hook-based detection gives OpenLid accurate working/idle state per agent session.
It is preferred over process detection whenever an agent can run lifecycle
commands.

## File Contract

OpenLid watches:

```text
~/.openlid/agents/
```

When a session is working, create or update:

```text
~/.openlid/agents/<agent-id>-<session>.json
```

with at least:

```json
{ "agent": "<agent-id>", "status": "working" }
```

When the session becomes idle, either delete that file or rewrite it with a status
other than `working`.

OpenLid treats files older than roughly six hours as stale and ignores them. This
prevents a crashed hook or agent from keeping the machine awake indefinitely.

## Filename and JSON Rules

- The file extension must be `.json`.
- `status` is case-insensitive after lowercasing and must equal `working`.
- `agent` is preferred from JSON when present.
- If `agent` is missing, OpenLid derives it from the filename by removing the
  extension and taking everything before the final dash.
- Multiple fresh files for the same agent count as multiple sessions.

## Built-In Hook Examples

| Agent | Script |
| --- | --- |
| Claude Code | `examples/hooks/claude-code/openlid-hook.sh` |
| Codex CLI | `examples/hooks/codex/openlid-hook.sh` |
| OpenCode | `examples/hooks/opencode/openlid-hook.sh` |
| Antigravity | `examples/hooks/antigravity/openlid-hook.sh` |
| Devin | `examples/hooks/devin/openlid-hook.sh` |

Each script accepts:

```sh
openlid-hook.sh <working|idle> [session-id]
```

The Claude Code script reads `session_id` from hook event JSON on stdin. The other
scripts accept an explicit second argument and also try to parse `session_id` from
stdin JSON when present.

## Testing a Hook Manually

Create a working status:

```sh
mkdir -p ~/.openlid/agents
printf '{"agent":"codex","status":"working","session":"manual"}\n' > ~/.openlid/agents/codex-manual.json
```

OpenLid should show Codex working and begin holding awake if guardrails allow it.

Clear the status:

```sh
rm -f ~/.openlid/agents/codex-manual.json
```

After the configured idle timeout, OpenLid should release the wake lock and
optionally sleep.

## Adding a New Hook Agent

1. Add a default agent in `OpenLid/Models/AppConfig.swift`:

   ```swift
   Agent(id: "new-agent", name: "New Agent",
         detection: AgentDetection(hookID: "new-agent", processNames: ["new-agent"]),
         iconName: "agent.custom")
   ```

2. Add an installable script under `examples/hooks/new-agent/`.
3. Add a README that explains where the target agent registers lifecycle commands.
4. Confirm the script writes `working` at start and removes or idles the file at
   stop.
5. Update `examples/hooks/README.md` and any user-facing docs.

## Process Detection Fallback

If an agent cannot run hooks, use process detection from Settings -> Agents.
Process detection checks running app names, bundle IDs, and CLI base command names
with **exact**, case-insensitive matching. It cannot distinguish idle from working
inside a long-lived app — a running process is reported as "running".

