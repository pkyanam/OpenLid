# Contributing to OpenLid

Thanks for helping make OpenLid better! The highest-value contributions are
**adding support for new AI coding agents**.

## Ways to add an agent

There are two detection types. Pick whichever the agent supports.

### 1. Process detection (works for any agent)

If the agent runs as a process (GUI app or CLI binary), OpenLid can watch for it.
No code changes are required — a user can add it in **Settings → Agents** by
specifying the process name. To ship it as a built-in default, add an entry to the
default agent list in `OpenLid/Models/AppConfig.swift`:

```swift
Agent(
    id: "cursor",
    name: "Cursor",
    detection: .process(names: ["Cursor"]),
    symbol: "cursorarrow.rays"
)
```

`names` are matched (case-insensitively) against running application names and
the output of `ps -axco command`. Add every plausible binary/app name.

### 2. Lifecycle hooks (preferred — real Working/Idle signal)

Hook-based agents give an accurate per-session signal. OpenLid watches the
directory `~/.openlid/agents/`. The contract is dead simple:

- **Working:** write a file `~/.openlid/agents/<agent-id>-<session>.json` containing
  at least `{"agent":"<agent-id>","status":"working"}`. Update its mtime as a heartbeat.
- **Idle/finished:** either delete that file, or rewrite it with `"status":"idle"`.

A file whose mtime is older than the configured stale timeout is treated as idle,
so a crashed agent never holds the lock forever.

To ship hook support:

1. Add the agent to the default list with `detection: .hook(agentID: "<agent-id>")`.
2. Add install-ready scripts under `examples/hooks/<agent-id>/` plus a short README
   explaining where to register them in that agent's config.

See `examples/hooks/claude-code/` for a complete reference implementation
(`openlid-hook.sh` plus the `settings.json` snippet).

## Code style

- Swift + SwiftUI, targeting macOS 14.
- Keep it dependency-light. The only external dependency is `HotKey`.
- No network calls, no telemetry — OpenLid is fully local by design.

## Building

```sh
xcodebuild -project OpenLid.xcodeproj -scheme OpenLid -configuration Debug build
```
