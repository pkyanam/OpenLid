# AGENTS.md — OpenLid

**This file is the point of truth for AI agents working in this repository.** Read it
fully before making changes. (`CLAUDE.md` just points here.)

---

## 1. What OpenLid is

OpenLid is a free, open-source **macOS menu bar utility** that keeps the Mac awake
**only while watched AI coding agents are working**, then lets it sleep. It's a native
SwiftUI app, fully local (no network, no telemetry), inspired by holdmylid.app.

- **Language/UI:** Swift + SwiftUI, `MenuBarExtra` (window style), `@Observable`.
- **Min target:** macOS 14 (Sonoma). Built with Xcode 26 (Swift 5 language mode).
- **Distribution:** Developer ID signed + notarized `.app`, shipped as zip + dmg via
  GitHub Releases.
- **Dependency:** one SPM package — [`HotKey`](https://github.com/soffes/HotKey) for the
  global shortcut. Keep dependencies minimal.

### Core promise / behavior

1. Detect when any watched agent is **working**.
2. While working, hold an IOKit power assertion so the Mac doesn't idle-sleep.
3. When all agents go idle for `idleTimeoutSeconds` (default 30s), release the lock and
   (optionally) ask the Mac to sleep.
4. Respect battery guardrails (cutoff %, plugged-in-only, Low Power Mode) and offer
   display-off options, notifications/chimes, a quick pause, and a ⌥⌘L global toggle.

---

## 2. Repository layout

```
OpenLid/
├── OpenLid.xcodeproj/            # Hand-authored project (objectVersion 77, file-system-synchronized group)
├── OpenLid/
│   ├── OpenLidApp.swift          # @main App: MenuBarExtra + Settings scenes; state-driven menu bar icon
│   ├── Models/
│   │   ├── Agent.swift           # AgentDetection (hook + process + excludes), Agent, AgentStatus
│   │   ├── AppConfig.swift       # Persisted settings; defaultAgents; normalized()
│   │   ├── AppState.swift        # @MainActor @Observable coordinator + 1s evaluation loop (the brain)
│   │   └── ConfigStore.swift     # JSON load/save in Application Support
│   ├── Power/
│   │   ├── PowerManager.swift    # IOPMAssertion wrappers (system + display)
│   │   └── SleepController.swift # AppleScript sleep + `pmset displaysleepnow`
│   ├── Monitoring/
│   │   ├── AgentMonitor.swift    # Combines hook + process detection -> [AgentStatus]
│   │   ├── BatteryMonitor.swift  # IOKit power sources + Low Power Mode
│   │   ├── HookWatcher.swift     # Watches ~/.openlid/agents/ (file-based signaling)
│   │   └── ProcessWatcher.swift  # Interpreter-aware program matching + exclude patterns
│   ├── Services/
│   │   ├── HotKeyManager.swift   # ⌥⌘L global toggle (HotKey lib)
│   │   └── NotificationManager.swift # Banners + system chimes
│   ├── UI/
│   │   ├── MenuBarView.swift     # The dropdown (header, battery, agents, pause, footer)
│   │   ├── SettingsView.swift    # General/Battery/Display/Agents/About tabs
│   │   └── Components/MenuComponents.swift # AgentIconView, PillButtonStyle, MenuActionRow
│   └── Assets.xcassets/          # agent.<id>.imageset brand icons (see §7)
├── scripts/
│   ├── generate_icons.py         # Generates agent brand icons into Assets.xcassets
│   ├── build_release.sh          # Archive → sign → notarize → staple → zip + dmg
│   └── ExportOptions.plist       # developer-id export config
├── examples/hooks/<agent>/       # Installable hook scripts + per-agent READMEs
├── docs/                         # architecture, configuration, agent-hooks, development, troubleshooting, audit-notes
├── .github/workflows/release.yml # Tag-triggered (v*) signed/notarized release
├── README.md  CONTRIBUTING.md  RELEASING.md  LICENSE
└── AGENTS.md  CLAUDE.md
```

---

## 3. How to build, run, and verify

**Always verify your changes build before finishing.**

```sh
# Debug build (no signing needed)
xcodebuild -project OpenLid.xcodeproj -scheme OpenLid -configuration Debug \
  -destination 'platform=macOS' CODE_SIGNING_ALLOWED=NO build

# Run the built app (menu bar only — no Dock icon)
open ~/Library/Developer/Xcode/DerivedData/OpenLid-*/Build/Products/Debug/OpenLid.app
```

- There is **no unit test target yet.** Verify by building + launching, and by checking
  detection logic against real `ps` output (see §6).
- When iterating on a running instance, note that `open` only **re-activates** an
  already-running OpenLid; fully quit it first (`pkill -x OpenLid`) to load a new build.
- The app logs via `NSLog` (prefix `OpenLid:`). View with:
  `log stream --predicate 'process == "OpenLid"' --style compact`.

### Release builds

See `RELEASING.md`. Locally: `scripts/build_release.sh` (uses the `OpenLid-Notary`
keychain profile). CI: push a `v*` tag (requires repo secrets). Don't publish releases
without explicit user approval.

---

## 4. Architecture & runtime flow

`AppState` (`@MainActor @Observable`) is the single source of runtime truth. It runs a
**1-second timer** (`tick()`) added to the main run loop in `.common` mode (so it keeps
updating while the popover is open). Each tick:

1. `BatteryMonitor.read()` → current `BatteryInfo`.
2. `persistIfNeeded()` → save config to disk if it changed (Equatable compare).
3. `AgentMonitor.evaluate(...)` → `[AgentStatus]` (hook signal wins over process).
4. Expire any active pause.
5. Decide the `HoldState` and drive `PowerManager` / notifications / sleep:
   - `off` (master toggle off) → release everything.
   - `paused` → release everything.
   - working **and** not battery-blocked → begin/continue session, hold assertion
     (`holding`).
   - working **but** battery-blocked → `blockedBattery`, notify once, release.
   - not working but a session was engaged → `willSleepSoon` during the
     `idleTimeoutSeconds` grace window; after it elapses → `finishSession()` (release,
     notify, optional `SleepController.sleepNow()`), state `idle`.

Key invariants:
- **Hook detection beats process detection.** Process detection only reports "running"
  (coarse); it cannot distinguish idle from working inside a long-lived process.
- Battery guardrails only apply on battery power (desktops / plugged-in are never
  blocked). See `AppState.batteryBlocksHold()`.
- OpenLid uses the **same public power assertions as `caffeinate`**. It cannot guarantee
  staying awake in every lid-closed-on-battery scenario — keep this honesty in docs.

---

## 5. Agent detection model (READ THIS before touching detection)

Defined in `Agent.swift`:

```swift
struct AgentDetection {
    var hookID: String?              // file-based hook signal (accurate, per-session)
    var processNames: [String]       // EXACT program names (case-insensitive) — fallback
    var excludeProcessPatterns: [String] // skip processes whose full command contains these
}
```

- **Hook detection** (`HookWatcher`): watches `~/.openlid/agents/`. A working session
  writes `~/.openlid/agents/<agent-id>-<session>.json` containing
  `{"agent":"<id>","status":"working"}`; idle deletes it or sets a non-"working" status.
  Files older than ~6h are treated as stale (crash safety).
- **Process detection** (`ProcessWatcher`): resolves the **effective program** of each
  process (interpreter-aware — `node /…/codex app-server` resolves to `codex`), then
  matches it **exactly** (case-insensitive) against `processNames`. A process is ignored
  if its full command line contains any `excludeProcessPatterns` substring. This is why
  Codex excludes `app-server` (CodexBar runs an always-on `codex app-server` daemon that
  must NOT count as an active session).
- **Hybrid:** an agent can set both. The hook wins; the process name lights it up as
  "running" before a hook is installed.

`AppConfig.normalized()` reconciles persisted config with `defaultAgents` on every load:
built-in detection/name/icon always come from code; the user's `enabled` toggles and any
`custom-`prefixed agents are preserved; removed/renamed built-ins are dropped. So you can
improve built-in detection without wiping user config — just edit `defaultAgents`.

---

## 6. How to add a new agent

1. **Add a default in `AppConfig.defaultAgents`** (`OpenLid/Models/AppConfig.swift`):
   ```swift
   Agent(id: "myagent", name: "My Agent",
         detection: AgentDetection(hookID: "myagent", processNames: ["myagent"]),
         iconName: "agent.myagent")
   ```
   - Use the **exact** process/program name. Verify against the user's machine:
     `ps -axo comm= | sed 's:.*/::' | sort -u | grep -i myagent`
   - Add `excludeProcessPatterns` if the tool spawns an always-on daemon that shares the
     program name (like Codex's `app-server`).
2. **Add the brand icon** (§7): edit `scripts/generate_icons.py`, run it, commit the new
   `agent.myagent.imageset`.
3. **Add an example hook** under `examples/hooks/myagent/` (script + README) if the agent
   supports lifecycle hooks. Mirror `examples/hooks/claude-code/` (the reference).
4. **Update docs:** `README.md` compatibility table, `examples/hooks/README.md`,
   `docs/configuration.md` (built-in agents table), `docs/agent-hooks.md`.
5. **Build + verify** detection against real `ps` output, then confirm the icon resolves
   (no "no image named" log; appears in compiled `Assets.car`).

The hook file contract is identical for every agent — only the wiring into the agent's
own hook/event system differs.

---

## 7. Icons (brand logos, not SF Symbols)

Agent rows use real brand icons from `Assets.xcassets/agent.<id>.imageset`, rendered by
`AgentIconView` (template glyphs tint to the label color; colored logos keep color and
dim to 0.5 opacity when idle). **Do not use random SF Symbols / emoji for agents.**

Icons are produced by `scripts/generate_icons.py`, which extracts brand SVG paths from
the trifecta source (`~/projects/trifecta/trifecta-desktop/apps/web/src/components/Icons.tsx`)
and decodes embedded PNGs:
- Vector glyphs (Claude, OpenAI, Cursor) → SVG imagesets, mostly `template` rendering.
- Colored logos (Antigravity PNG, Devin PNG) → `original` rendering.
- OpenCode uses a hand-authored monochrome glyph (its two-tone SVG flattens to a blob as
  a template).

After editing the generator: `python3 scripts/generate_icons.py`, rebuild, then confirm
with `assetutil --info` on the compiled `Assets.car`.

---

## 8. Configuration & persistence

- File: `~/Library/Application Support/OpenLid/config.json` (`ConfigStore`). Decoding is
  tolerant (missing keys default; schema mismatches fall back to defaults).
- All settings live in `AppConfig` and are edited via the Settings UI (bound through
  `@Bindable`). Changes auto-save within ~1s via `AppState.persistIfNeeded()`.
- See `docs/configuration.md` for the full field/default table.

---

## 9. Conventions & gotchas

- **Style:** compact, idiomatic Swift; match existing patterns. Don't add or remove
  comments gratuitously. No emojis in code/UI unless asked.
- **Accessory app:** `LSUIElement = YES` (no Dock icon). Opening the Settings window must
  call `NSApp.activate(ignoringOtherApps:)` + the `openSettings` environment action,
  otherwise the window opens hidden. `SettingsLink` does **not** work reliably here.
- **⌘,** works only while the dropdown is open (accessory apps have no app menu). Never
  register ⌘, as a global hotkey (it would hijack it system-wide).
- **Concurrency:** `AppState` is `@MainActor`. Keep UI/state on the main actor.
- **No network, no telemetry. Ever.** This is a core product promise.
- **Don't commit secrets.** Never print/commit Apple credentials, `.p12`, notary
  passwords, or anything from `~/.hermes/.env` or `~/.hermes/config.yaml`.
- The project is a hand-written `project.pbxproj` using a file-system-synchronized group —
  new files under `OpenLid/` are picked up automatically (no pbxproj edits needed for new
  source files), but new top-level groups or build settings do need manual pbxproj edits.

---

## 10. Git & PR conventions

- Branch off `main`. Make focused commits with a clear "why".
- Commit trailer used in this repo:
  ```
  Generated with [Devin](https://devin.ai)

  Co-Authored-By: Devin <158243242+devin-ai-integration[bot]@users.noreply.github.com>
  ```
- **Do not** `git push`, publish releases, or perform destructive/irreversible actions
  without explicit user approval.
- Keep README/docs in sync with behavior changes (detection model, agent list, etc.).

---

## 11. Reference docs

- `docs/architecture.md` — runtime flow, modules, state machine, power behavior.
- `docs/configuration.md` — settings, defaults, storage paths.
- `docs/agent-hooks.md` — hook file contract + built-in agents.
- `docs/development.md` — common tasks and project layout.
- `docs/troubleshooting.md` — runtime issues + diagnostics.
- `docs/audit-notes.md` — known limitations and follow-ups.
- `CONTRIBUTING.md` — adding agents (the highest-value contribution).
- `RELEASING.md` — signing, notarization, and CI release secrets.
