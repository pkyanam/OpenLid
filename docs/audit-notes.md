# Audit Notes

These notes summarize a read-only audit of the current repository. They are not a
bug list with confirmed failures; they are implementation facts and follow-up
risks worth tracking.

## Scope Reviewed

- Root README and contributing guide.
- Swift app source under `OpenLid/`.
- Xcode project and shared scheme.
- Swift package resolution file.
- Hook examples under `examples/hooks/`.

## Implementation Observations

- The app is fully local in the reviewed source. No network APIs are used by app
  code.
- The only external dependency is `HotKey` for global shortcut handling.
- Power assertions are created and released through a dedicated `PowerManager`,
  which reduces the chance of leaking assertion IDs.
- `AppState` is the central coordinator and owns long-lived dependencies.
- Hook detection defaults to fresh `working` files and has a six-hour stale-file
  cutoff.
- Process detection is intentionally coarse and can over-count helper processes.
- Settings persistence is simple and frequent: changed config is saved on the next
  one-second tick.
- Release builds enable Hardened Runtime; Debug builds do not.
- No unit, integration, or UI test targets are present.

## Follow-Up Risks

| Risk | Impact | Notes |
| --- | --- | --- |
| No automated tests | Regressions in the state machine, config decoding, and hook parsing may go unnoticed. | `AppState` logic is a good first target for tests, but it currently constructs concrete dependencies internally. |
| Auto-sleep depends on Automation permission | Users may think auto-sleep is broken if macOS permission is denied. | Troubleshooting docs now call this out. |
| `NotificationManager.authorized` is stored but not read | Not harmful, but the app does not surface denied notification permission. | Could be used for UI feedback later. |
| `holdDisplayAwake` is implemented but unused | Dead or future-facing API can confuse maintainers. | Current behavior only forces display off; it does not hold display awake. |
| Delayed display-off closure is not cancelled | A scheduled display-off after finish can still run if agents restart before the delay expires. | This only applies when auto-sleep is disabled and `displayOffAfterFinishSeconds > 0`. |
| Process detection cannot tell idle from working | A long-lived agent process is reported as "running" the whole time it is open. | Hook detection is preferred for supported agents; matching is exact to avoid helper/false-positive noise. |
| Hook docs for Codex/OpenCode/Antigravity/Devin are generic | Users may need version-specific lifecycle config. | The examples include scripts but not exact event mappings for every tool version. |

## Suggested Test Coverage

- `HookWatcher.agentID(fromFileName:)` behavior through public working-session
  scenarios.
- Hook JSON parsing for explicit `agent`, missing `agent`, idle status, stale
  files, and multiple sessions.
- `ProcessWatcher.matchCount` exact, case-insensitive matching (no false positives
  on helper processes such as `CursorUIViewService`).
- `AppConfig` encode/decode compatibility when adding new fields.
- `AppState` transitions for off, pause, holding, idle grace, battery block, and
  auto-sleep disabled behavior.

## Documentation Changes Made From Audit

- Added architecture documentation with runtime state flow.
- Added configuration reference with defaults and storage paths.
- Added hook integration reference and manual testing commands.
- Added development guide with project settings and verification checklist.
- Added troubleshooting guide for common runtime issues.

