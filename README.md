# KUAL Compat (For Kindle Firmware 5.19.4+)

An experimental KPM-native compatibility runner for firmware 5.19.4+.

It lists and runs trusted, static legacy KUAL extension shell actions. It does
not restore the original Java KUAL Booklet or make legacy native applications
compatible.

## Manual installation (recommended for testing)

1. Download [`kual-compat_0.1.0_kindlehf.kpkg`](packages/kual-compat_0.1.0_kindlehf.kpkg).
2. Copy it to the Kindle's root USB storage, next to `documents` rather than inside it.
3. In the Kindle search bar, run:

```text
;kpm --fbink install file:///mnt/us/kual-compat_0.1.0_kindlehf.kpkg
```

4. List compatible legacy extension actions:

```text
;kpm --fbink launch kual-compat list
```

Then tap the **KUAL Compat** scriptlet in the Kindle library, or run the list
command again whenever you add or change legacy extensions.

Only use legacy extensions from sources you trust: their actions are shell
commands and run with the permissions provided by the jailbreak.

## Remove

```text
;kpm uninstall kual-compat
```
