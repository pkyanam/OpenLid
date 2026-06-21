# OpenAI Codex CLI → OpenLid hook

Reports **Working / Idle** to OpenLid using the shared file contract (see
[../README.md](../README.md)).

## Install

```sh
mkdir -p ~/.openlid/hooks/codex
cp openlid-hook.sh ~/.openlid/hooks/codex/
chmod +x ~/.openlid/hooks/codex/openlid-hook.sh
```

## Wire it up

Call the script when a Codex turn starts and finishes:

```sh
# work starting
~/.openlid/hooks/codex/openlid-hook.sh working
# work finished
~/.openlid/hooks/codex/openlid-hook.sh idle
```

Codex CLI can invoke an external program on events via its `notify` setting in
`~/.codex/config.toml`. Point it at a small wrapper that maps the event type to
`working` / `idle`, e.g.:

```toml
notify = ["/Users/<YOU>/.openlid/hooks/codex/codex-notify.sh"]
```

…where `codex-notify.sh` reads the event JSON Codex passes and calls
`openlid-hook.sh working` or `openlid-hook.sh idle` accordingly. Exact event names
depend on your Codex version — see `openlid-hook.sh` for the stdin `session_id`
parsing you can reuse.

> If you don't want to deal with events yet, you can fall back to **process
> detection** in OpenLid's Settings → Agents instead.
