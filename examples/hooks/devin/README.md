# Devin CLI → OpenLid hook

Reports **Working / Idle** to OpenLid using the shared file contract (see
[../README.md](../README.md)).

By default OpenLid also detects Devin via **process detection** (the `devin`
process), so Devin lights up as "running" even without this hook installed. Install
the hook for accurate per-session Working/Idle instead of coarse "process alive".

## Install

```sh
mkdir -p ~/.openlid/hooks/devin
cp openlid-hook.sh ~/.openlid/hooks/devin/
chmod +x ~/.openlid/hooks/devin/openlid-hook.sh
```

## Wire it up

Call the script when a Devin session starts working and when it stops:

```sh
~/.openlid/hooks/devin/openlid-hook.sh working
~/.openlid/hooks/devin/openlid-hook.sh idle
```

Hook these into the Devin CLI's lifecycle/event mechanism. The script accepts an
optional explicit session id as a second argument and can also read `session_id`
from stdin JSON.
