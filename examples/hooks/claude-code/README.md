# Claude Code → OpenLid hook

This makes Claude Code report **Working / Idle** to OpenLid with real per-session accuracy.

## Install

1. Copy the script somewhere stable and make it executable:

   ```sh
   mkdir -p ~/.openlid/hooks/claude-code
   cp openlid-hook.sh ~/.openlid/hooks/claude-code/
   chmod +x ~/.openlid/hooks/claude-code/openlid-hook.sh
   ```

2. Add the hooks to your Claude Code settings (`~/.claude/settings.json`). Merge this
   into the existing `"hooks"` object if you already have one. **Use the absolute path**
   (replace `<YOU>` with your username) so it works regardless of the shell:

   ```json
   {
     "hooks": {
       "UserPromptSubmit": [
         { "hooks": [ { "type": "command", "command": "/Users/<YOU>/.openlid/hooks/claude-code/openlid-hook.sh working" } ] }
       ],
       "PreToolUse": [
         { "matcher": "*", "hooks": [ { "type": "command", "command": "/Users/<YOU>/.openlid/hooks/claude-code/openlid-hook.sh working" } ] }
       ],
       "Stop": [
         { "hooks": [ { "type": "command", "command": "/Users/<YOU>/.openlid/hooks/claude-code/openlid-hook.sh idle" } ] }
       ]
     }
   }
   ```

That's it. When Claude starts responding or runs a tool, OpenLid sees "working"; when
Claude stops, the status file is removed and the idle timeout begins.

## How it works

The script writes `~/.openlid/agents/claude-code-<session>.json` containing
`{"agent":"claude-code","status":"working"}` while working, and deletes it when idle.
OpenLid also treats any file untouched for ~6 hours as stale, so a crashed session
never holds your Mac awake forever.
