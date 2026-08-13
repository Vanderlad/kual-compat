# KUAL Compat

KUAL Compat is a KPM-native replacement for the *action runner* part of KUAL.
It is intended for firmware 5.19.4 and later, where Amazon removed the Java
runtime required by the original KUAL Booklet.

It does not install a Booklet, write `/opt`, or modify `appreg.db`.

## Current scope

It scans `/mnt/us/extensions/*/menu.json` for the common legacy KUAL menu-item
layout and lists actions using KPM:

```text
;kpm --fbink launch kual-compat list
;kpm --fbink launch kual-compat run <extension-folder> <item-number>
```

The first release intentionally supports only trusted, static menu entries
where `name` and `action` are on the same JSON line. It does not claim to make
old ARM binaries, GTK apps, or device-specific extensions compatible.

## Security

Legacy KUAL actions are shell commands. Run extensions only when you trust
their source and understand their purpose.
