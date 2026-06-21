# Gemini → OpenLid hook

Reports **Working / Idle** to OpenLid using the shared file contract (see
[../README.md](../README.md)).

## Install

```sh
mkdir -p ~/.openlid/hooks/gemini
cp openlid-hook.sh ~/.openlid/hooks/gemini/
chmod +x ~/.openlid/hooks/gemini/openlid-hook.sh
```

## Wire it up

Call the script when the Gemini CLI starts working and when it stops:

```sh
~/.openlid/hooks/gemini/openlid-hook.sh working
~/.openlid/hooks/gemini/openlid-hook.sh idle
```

Hook these into the Gemini CLI's event/lifecycle mechanism. The exact configuration
depends on your CLI version; the script accepts an optional explicit session id as a
second argument and can also read `session_id` from stdin JSON.

> Until hooks are wired, OpenLid's **process detection** (Settings → Agents) works as
> a fallback.
