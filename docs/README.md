# OpenLid Documentation

OpenLid is a macOS menu bar utility that keeps the system awake while configured
AI coding agents are working, then releases the wake lock when they go idle.

This documentation was produced from a read-only audit of the codebase. It
describes the current implementation rather than a future design.

## Contents

- [Architecture](architecture.md) - runtime flow, modules, state machine, and power behavior.
- [Configuration](configuration.md) - persisted settings, defaults, storage paths, and UI mapping.
- [Agent Hooks](agent-hooks.md) - hook file contract, built-in agents, and custom integrations.
- [Development](development.md) - project layout, build commands, dependencies, and contribution workflow.
- [Troubleshooting](troubleshooting.md) - common runtime issues and diagnostic commands.
- [Audit Notes](audit-notes.md) - implementation observations, limitations, and follow-up risks.

## Quick Facts

| Area | Current behavior |
| --- | --- |
| Platform | macOS 14+ SwiftUI menu bar app |
| Entry point | `OpenLid/OpenLidApp.swift` |
| Main coordinator | `OpenLid/Models/AppState.swift` |
| Wake lock API | IOKit `IOPMAssertionCreateWithName` |
| Sleep/display commands | `/usr/bin/osascript` and `/usr/bin/pmset displaysleepnow` |
| Config path | `~/Library/Application Support/OpenLid/config.json` |
| Hook status path | `~/.openlid/agents/` |
| External dependency | Swift package `HotKey` pinned to 0.2.1 |
| Tests | No test targets are currently present |

## Runtime Summary

1. `OpenLidApp` creates a shared `AppState` and exposes it to the menu bar extra
   and settings window.
2. `AppState` loads local JSON configuration, registers the global hotkey,
   requests notification permission, starts a hook directory watcher, and starts a
   one-second timer.
3. Each tick reads battery state, persists changed settings, evaluates enabled
   agents, applies guardrails, and transitions the hold state.
4. When an agent is working and guardrails allow it, `PowerManager` creates a
   `PreventUserIdleSystemSleep` assertion.
5. When agents are idle for the configured timeout, OpenLid releases assertions
   and optionally asks macOS to sleep.

