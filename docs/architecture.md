# Architecture

OpenLid is intentionally small: a SwiftUI shell, one observable app coordinator,
lightweight monitor classes, and thin wrappers around macOS system APIs.

## Module Map

| Path | Responsibility |
| --- | --- |
| `OpenLid/OpenLidApp.swift` | App entry point, menu bar extra, settings scene, menu bar icon selection. |
| `OpenLid/Models/AppState.swift` | Main state machine, timer loop, persistence trigger, battery guardrails, wake/sleep transitions. |
| `OpenLid/Models/AppConfig.swift` | User-facing settings and built-in agent defaults. |
| `OpenLid/Models/ConfigStore.swift` | JSON load/save under Application Support. |
| `OpenLid/Models/Agent.swift` | Agent detection model and live agent status model. |
| `OpenLid/Monitoring/AgentMonitor.swift` | Combines hook and process detection into live status rows. |
| `OpenLid/Monitoring/HookWatcher.swift` | Creates and watches `~/.openlid/agents/`, reads hook JSON files, applies stale timeout. |
| `OpenLid/Monitoring/ProcessWatcher.swift` | Reads running GUI apps and CLI process names, matches configured process patterns. |
| `OpenLid/Monitoring/BatteryMonitor.swift` | Reads battery, AC, charging, and Low Power Mode state. |
| `OpenLid/Power/PowerManager.swift` | Owns IOKit power assertion IDs and releases them. |
| `OpenLid/Power/SleepController.swift` | Runs system commands to sleep the Mac or turn the display off. |
| `OpenLid/Services/NotificationManager.swift` | Notification authorization, banners, and system sounds. |
| `OpenLid/Services/HotKeyManager.swift` | Registers the fixed global `Option+Command+L` shortcut. |
| `OpenLid/UI/*` | Menu bar dropdown, settings tabs, and small reusable controls. |

## State Machine

`HoldState` has six UI-visible states:

| State | Meaning | Assertion behavior |
| --- | --- | --- |
| `off` | Master toggle is disabled. | Releases all assertions. |
| `paused` | User paused OpenLid temporarily. | Releases all assertions. |
| `idle` | Enabled, no agent is working. | No assertion. |
| `holding` | One or more agents are working. | Holds system awake. |
| `willSleepSoon` | Agents are idle, but idle timeout has not elapsed. | Keeps holding during grace period. |
| `blockedBattery` | Agents are working, but a battery guardrail prevents holding. | Releases all assertions, may sleep. |

The state machine lives in `AppState.tick()`. It runs once per second and is also
called immediately when hook directory changes arrive.

## Tick Flow

Each `tick()` performs this sequence:

1. Read battery state through `BatteryMonitor.read()`.
2. Save `AppConfig` if it differs from the last persisted copy.
3. Evaluate enabled agents with `AgentMonitor.evaluate(...)`.
4. Expire any temporary pause whose deadline has passed.
5. If globally disabled, set `off` and release assertions.
6. If paused, set `paused` and release assertions.
7. Compute battery guardrails.
8. If any agent is working:
   - If blocked, set `blockedBattery`, notify once, release assertions, and
     optionally sleep.
   - Otherwise begin or refresh a holding session and set `holding`.
9. If no agents are working but a session is engaged:
   - Start or continue the idle grace timer.
   - Keep holding as `willSleepSoon` until the configured timeout elapses.
   - Finish the session, release assertions, notify, and optionally sleep.
10. If no session is engaged, set `idle`.

## Agent Detection

OpenLid supports two detection mechanisms.

Hook detection is the preferred mechanism. Agent lifecycle integrations write JSON
files into `~/.openlid/agents/`; OpenLid counts fresh files whose status is
`working`. Files are ignored when deleted, rewritten with another status, or older
than the six-hour stale timeout in `AppState`.

Process detection is coarse. OpenLid collects lowercased GUI application names,
bundle identifiers, and CLI executable (base command) names, then treats an
**exact** name match as a running process. Exact matching avoids false positives
like `cursor` matching `CursorUIViewService`. A live process means "possibly
working", not "actively processing a task"; hook detection wins when available.

## Power and Sleep Behavior

`PowerManager` uses `IOPMAssertionCreateWithName` with:

- `kIOPMAssertionTypePreventUserIdleSystemSleep` for the main wake lock.
- `kIOPMAssertionTypePreventUserIdleDisplaySleep` support exists, but the current
  state machine does not call `holdDisplayAwake`.

`SleepController` uses public, non-sudo commands:

- `osascript -e 'tell application "System Events" to sleep'` to request system sleep.
- `pmset displaysleepnow` to turn the display off.

OpenLid prevents idle sleep. It cannot override all Apple clamshell sleep behavior,
especially lid-closed battery scenarios without external display support.

## Persistence Model

Settings are persisted opportunistically from the main tick loop. Any UI mutation
to `app.config` will be saved within about one second as long as the app remains
running.

The config file is JSON at:

```text
~/Library/Application Support/OpenLid/config.json
```

If the file is missing or cannot be decoded, defaults from `AppConfig` are used.

