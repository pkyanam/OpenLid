# OpenCode → OpenLid hook

Reports **Working / Idle** to OpenLid using the shared file contract (see
[../README.md](../README.md)).

## Install

```sh
mkdir -p ~/.openlid/hooks/opencode
cp openlid-hook.sh ~/.openlid/hooks/opencode/
chmod +x ~/.openlid/hooks/opencode/openlid-hook.sh
```

## Wire it up

Call the script when a session starts working and when it stops:

```sh
~/.openlid/hooks/opencode/openlid-hook.sh working
~/.openlid/hooks/opencode/openlid-hook.sh idle
```

Hook these calls into OpenCode's lifecycle/event mechanism (e.g. a session-start and
session-idle/stop event). The exact configuration depends on your OpenCode version;
the script accepts an optional second argument for an explicit session id:

```sh
~/.openlid/hooks/opencode/openlid-hook.sh working "$MY_SESSION_ID"
```

> Until hooks are wired, OpenLid's **process detection** (Settings → Agents) works as
> a fallback.
