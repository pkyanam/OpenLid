# OpenLid

**Close the lid. Keep coding.**

OpenLid is a free, open-source macOS menu bar utility that keeps your Mac awake
while your AI coding agents finish the job, then lets it sleep automatically once
they are done.

It's an open, transparent alternative inspired by [holdmylid.app](https://holdmylid.app),
built for the community. No network calls, no telemetry, fully local.

> **Status:** v0.1 (MVP). Core wake/sleep logic, agent monitoring (process + hooks),
> battery guardrails, display control, notifications, menu bar UI and a global
> shortcut are implemented.

## Documentation

Comprehensive project documentation lives in [`docs/`](docs/):

- [Architecture](docs/architecture.md) - runtime flow, modules, state machine, and power behavior.
- [Configuration](docs/configuration.md) - persisted settings, defaults, storage paths, and UI mapping.
- [Agent Hooks](docs/agent-hooks.md) - hook file contract, built-in agents, and custom integrations.
- [Development](docs/development.md) - project layout, build commands, dependencies, and contribution workflow.
- [Troubleshooting](docs/troubleshooting.md) - common runtime issues and diagnostic commands.
- [Audit Notes](docs/audit-notes.md) - implementation observations, limitations, and follow-up risks.

## How it works

OpenLid creates a macOS power assertion (via IOKit `IOPMAssertion`, the same public
API behind `caffeinate`) **only while a watched agent reports that it's working**.
When all agents go idle for a configurable timeout (default 30s), OpenLid releases
the assertion and — if you enable auto-sleep — asks the system to sleep.

Agents are detected two ways, and most use **both**:

| Method | Accuracy | Used for |
| --- | --- | --- |
| **Lifecycle hooks** (file-based signaling) | High — real Working/Idle per session | Claude Code, Codex CLI, OpenCode, Antigravity, Devin |
| **Process detection** | Coarse — "process is alive" = potentially working | Cursor, plus a fallback for all CLI agents |

When an agent has both, the hook signal wins and process detection is only a
fallback — so agents still light up as "running" before you've installed their
hooks, then upgrade to accurate per-session "working / idle" once you do. Process
matching is **exact** (case-insensitive) on the process/app name, so `cursor` won't
match `CursorUIViewService` and `code` won't match `Xcode`.

Hook scripts write small status files into `~/.openlid/agents/`, which OpenLid
watches. See [`examples/hooks/`](examples/hooks/) for ready-to-install scripts. You
can add your own agents (process detection) in **Settings → Agents**.

## Features

- **Agent-driven wake lock** — stays awake only while agents are working.
- **Idle timeout** — waits N seconds after agents finish before allowing sleep.
- **Battery guardrails** — cut-off threshold, "only when plugged in", respects Low Power Mode.
- **Display control** — turn the display off on lid close, while working, or after agents finish.
- **Auto-sleep** — optionally sleeps the Mac when agents finish or the battery limit is hit.
- **Menu bar UI** — live status, battery, per-agent working/idle, quick pause (30 min / 1 hour).
- **Global shortcut** — ⌥⌘L toggles the whole system on/off.
- **Notifications + chimes** — when engaging, when agents finish, and when the battery limit is hit.

## Build & run

Requires macOS 14+ and Xcode 16+ (developed against Xcode 26).

```sh
git clone https://github.com/your-org/OpenLid.git
cd OpenLid
open OpenLid.xcodeproj   # then Run (⌘R)
```

Or from the command line:

```sh
xcodebuild -project OpenLid.xcodeproj -scheme OpenLid -configuration Debug build
```

OpenLid runs as a menu bar item with no Dock icon.

## Configuration

OpenLid stores settings locally at:

```text
~/Library/Application Support/OpenLid/config.json
```

Hook integrations write working/idle status files under:

```text
~/.openlid/agents/
```

See [Configuration](docs/configuration.md) for all defaults and storage paths.

## Limitations (honest, like Amphetamine)

OpenLid uses the **same public power assertions** as `caffeinate` and Amphetamine.
These prevent *idle* sleep, but macOS may still sleep in some **lid-closed**
scenarios — most notably on **battery with no external display attached**, where
Apple's clamshell behavior can force sleep regardless of assertions. OpenLid
cannot guarantee staying awake in every lid-closed situation. When in doubt, stay
plugged in or attach an external display.

OpenLid never disables SIP, never requires `sudo`, and never modifies system
power settings behind your back.

## Contributing

Adding new agents is the highest-value contribution. Start with
[CONTRIBUTING.md](CONTRIBUTING.md), then see [Development](docs/development.md)
and [Agent Hooks](docs/agent-hooks.md).

## License

[MIT](LICENSE)
