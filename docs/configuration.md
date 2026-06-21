# Configuration

OpenLid stores all user-facing settings in `AppConfig`, encoded as JSON by
`ConfigStore`.

## Storage

| Item | Path |
| --- | --- |
| Config directory | `~/Library/Application Support/OpenLid/` |
| Config file | `~/Library/Application Support/OpenLid/config.json` |
| Hook status files | `~/.openlid/agents/` |
| Example installed hooks | `~/.openlid/hooks/<agent-id>/` |

If `config.json` is absent or invalid, OpenLid falls back to default settings.
The app does not perform network calls or telemetry.

## Default Settings

| Setting | Default | UI location | Effect |
| --- | --- | --- | --- |
| `globalEnabled` | `true` | Menu header, General | Master on/off switch. |
| `idleTimeoutSeconds` | `30` | General | Grace period after all agents go idle. |
| `autoSleep` | `true` | General | Requests system sleep after a completed session or battery block. |
| `onlyWhenPluggedIn` | `false` | Battery | Blocks holding while on battery. |
| `batteryCutoffEnabled` | `true` | Battery | Enables percentage cutoff. |
| `batteryCutoffPercent` | `20` | Battery | Stops holding at or below this battery percentage. |
| `respectLowPowerMode` | `true` | Battery | Blocks holding when macOS Low Power Mode is active. |
| `displayOffWhileWorking` | `false` | Display | Turns the display off when a holding session begins. |
| `displayOffAfterFinishSeconds` | `0` | Display | If auto-sleep is off, optionally turns display off after finish. |
| `notificationsEnabled` | `true` | General | Shows banners for lifecycle events. |
| `soundsEnabled` | `true` | General | Plays system sounds for lifecycle events. |
| `agents` | Built-in list | Agents | Agent definitions and enabled flags. |

## Built-In Agents

Each agent may use a hook, a process-name fallback, or both. When both are set the
hook signal wins and the process name only lights the agent up as "running" until
its hook is installed.

| Agent | ID | Detection | Hook ID / process names |
| --- | --- | --- | --- |
| Claude Code | `claude-code` | Hook + process | hook `claude-code`, process `claude` |
| OpenAI Codex CLI | `codex` | Hook + process | hook `codex`, process `codex` |
| OpenCode | `opencode` | Hook + process | hook `opencode`, process `opencode` |
| Antigravity | `antigravity` | Hook + process | hook `antigravity`, process `Antigravity`, `Antigravity IDE` |
| Devin | `devin` | Hook + process | hook `devin`, process `devin` |
| Hermes | `hermes` | Hook + process | hook `hermes`, process `hermes` |
| Cursor | `cursor` | Process | process `Cursor` |

## Battery Guardrail Rules

Battery guardrails are evaluated in `AppState.batteryBlocksHold()`.

OpenLid blocks a hold when:

- Low Power Mode is enabled and `respectLowPowerMode` is true.
- The Mac has a battery, is not on AC power, and `onlyWhenPluggedIn` is true.
- The Mac has a battery, is not on AC power, the cutoff is enabled, and current
  battery percentage is at or below `batteryCutoffPercent`.

Desktop Macs and plugged-in laptops are not blocked by percentage or
plugged-in-only settings.

## Editing Configuration Manually

The Settings UI is the safest path. If manual editing is needed:

1. Quit OpenLid.
2. Edit `~/Library/Application Support/OpenLid/config.json`.
3. Relaunch OpenLid.

Invalid JSON or incompatible schema changes cause OpenLid to log the decode error
and use defaults for that launch.

## Custom Process Agent

Settings -> Agents can add process-detected agents. The UI captures:

- Display name.
- Comma-separated process names.

OpenLid stores these as a generated `custom-<id>` agent with
`detection: AgentDetection(processNames: ...)` and uses **exact**, case-insensitive
name matching against running apps and process command names.

