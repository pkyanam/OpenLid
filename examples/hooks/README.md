# OpenLid agent hooks

Hook-based agents give OpenLid an accurate **Working / Idle** signal per session
(far better than process detection). The contract is intentionally tiny so it's easy
to wire into any agent that can run a command on lifecycle events.

## The contract

OpenLid watches `~/.openlid/agents/`.

- **Working:** create/update `~/.openlid/agents/<agent-id>-<session>.json` containing
  at least:

  ```json
  { "agent": "<agent-id>", "status": "working" }
  ```

- **Idle / finished:** delete that file (or rewrite it with `"status":"idle"`).

A file untouched for ~6 hours is treated as stale (idle), so a crashed agent never
holds your Mac awake forever.

The scripts in each subfolder implement exactly this — call them with `working` when
the agent starts and `idle` when it stops.

| Agent | Folder | Notes |
| --- | --- | --- |
| Claude Code | [`claude-code/`](claude-code/) | Full reference: script + `settings.json` hooks |
| OpenAI Codex CLI | [`codex/`](codex/) | Wire into Codex's notify/event mechanism |
| OpenCode | [`opencode/`](opencode/) | Wire into OpenCode's hook/event mechanism |
| Gemini | [`gemini/`](gemini/) | Wire into the Gemini CLI's event mechanism |

> Exact hook/event names differ between tools and versions. The Claude Code example is
> complete; the others ship the same script plus guidance, since their hook surfaces
> vary. Contributions that pin down the exact config for each tool are very welcome —
> see [CONTRIBUTING.md](../../CONTRIBUTING.md).
