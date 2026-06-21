# Troubleshooting

## OpenLid Does Not Keep the Mac Awake

Check whether OpenLid sees an agent as working. The menu should show at least one
working agent. If not, test a manual hook file:

```sh
mkdir -p ~/.openlid/agents
printf '{"agent":"codex","status":"working","session":"manual"}\n' > ~/.openlid/agents/codex-manual.json
```

If the agent becomes working, the issue is in the agent hook integration. If it
does not, confirm that the corresponding agent is enabled in Settings -> Agents.

Also check battery guardrails:

- Low Power Mode blocks holds by default.
- `Only hold awake when plugged in` blocks holds while on battery.
- The battery cutoff blocks holds at or below the configured threshold.

## The Mac Still Sleeps With the Lid Closed

OpenLid uses public idle-sleep assertions. macOS may still force sleep in some
lid-closed clamshell situations, especially while on battery and without an
external display. This is a platform limitation, not a hook or config issue.

Best practical options:

- Keep the Mac plugged in.
- Use an external display or normal clamshell setup.
- Avoid relying on lid-closed battery operation for critical long-running jobs.

## Auto-Sleep Does Not Work

Auto-sleep runs:

```sh
/usr/bin/osascript -e 'tell application "System Events" to sleep'
```

The first successful app-triggered call may require macOS Automation permission
for OpenLid to control System Events. Check System Settings -> Privacy & Security
-> Automation.

You can test the underlying command manually:

```sh
osascript -e 'tell application "System Events" to sleep'
```

## Display-Off Does Not Work

Display-off runs:

```sh
/usr/bin/pmset displaysleepnow
```

Test it manually:

```sh
pmset displaysleepnow
```

The setting `Turn display off after finish` only applies when auto-sleep is off.
If auto-sleep is on, OpenLid asks the whole system to sleep instead.

## Process Detection Misses or Misfires

Process detection uses **exact**, case-insensitive matching against GUI app names,
bundle identifiers, and CLI base command names (`ps -axo comm=`). If an agent isn't
detected, check its real process name:

```sh
ps -axo comm= | sed 's:.*/::' | sort -u | grep -i <name>
```

Then add that exact name in Settings -> Agents. Exact matching avoids the old
false positives (e.g. `cursor` matching `CursorUIViewService`), so use the precise
name rather than a fragment. Use lifecycle hooks for accurate working/idle state
when possible.

## Inspect Hook Files

List current hook status files:

```sh
ls -la ~/.openlid/agents
```

Print their contents:

```sh
for file in ~/.openlid/agents/*.json; do
  [ -e "$file" ] || continue
  printf '\n%s\n' "$file"
  cat "$file"
done
```

Clear stale manual files:

```sh
rm -f ~/.openlid/agents/*.json
```

## Reset OpenLid Settings

Quit OpenLid, then move the config aside:

```sh
mv "$HOME/Library/Application Support/OpenLid/config.json" \
   "$HOME/Library/Application Support/OpenLid/config.json.bak"
```

Relaunch OpenLid. It will recreate defaults on the next settings change.

