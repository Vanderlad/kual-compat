# KUAL Compat (For Kindle Firmware 5.19.4+)

An experimental direct Véra scriptlet for Kindle firmware 5.19.4 and later.

It scans legacy KUAL extension folders and lists compatible static shell actions.
It does not restore the original Java KUAL Booklet, alter system files, execute
an action automatically, or make old native applications compatible.

## Install

1. Download [`KUAL Compat.sh`](scriptlets/KUAL%20Compat.sh).
2. Copy it directly into the Kindle's `documents` folder.
3. Safely eject and unplug the Kindle. It should appear as **KUAL Compat** in
   the Library; tap it to list compatible legacy extension actions.

The script scans this location:

```text
/mnt/us/extensions/*/menu.json
```

Only use legacy extensions from sources you trust: their actions are shell
commands and may run with the permissions provided by the jailbreak.

## Scope and limitations

- It lists only common static menu items where `name` and `action` share a
  line in `menu.json`.
- It does not yet offer a tap-to-run action menu.
- It does not make older ARM, GTK, Java, or device-specific extensions work.
- It does not require KPM, a repository, or a `.kpkg` package.
