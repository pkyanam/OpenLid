# Antigravity → OpenLid hook

Reports **Working / Idle** to OpenLid using the shared file contract (see
[../README.md](../README.md)).

> Antigravity is Google's agentic coding tool that supersedes the standalone Gemini
> CLI. OpenLid also detects it via **process detection** (the `Antigravity`
> process/app), so it lights up as "running" even without this hook installed.

## Install

```sh
mkdir -p ~/.openlid/hooks/antigravity
cp openlid-hook.sh ~/.openlid/hooks/antigravity/
chmod +x ~/.openlid/hooks/antigravity/openlid-hook.sh
```

## Wire it up

Call the script when a session starts working and when it stops:

```sh
~/.openlid/hooks/antigravity/openlid-hook.sh working
~/.openlid/hooks/antigravity/openlid-hook.sh idle
```

Hook these into Antigravity's lifecycle/event mechanism. The script accepts an
optional explicit session id as a second argument and can also read `session_id`
from stdin JSON.
