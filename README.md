# KUAL Compat

An experimental KPM-native compatibility runner for firmware 5.19.4+.

It lists and runs trusted, static legacy KUAL extension shell actions. It does
not restore the original Java KUAL Booklet or make legacy native applications
compatible.

## Install

```text
;kpm add-repo https://raw.githubusercontent.com/Vanderlad/kual-compat/main/manifest.json
;kpm update
;kpm install kual-compat
```

Then tap the **KUAL Compat** scriptlet in the Kindle library, or run:

```text
;kpm --fbink launch kual-compat list
```

Only use legacy extensions from sources you trust: their actions are shell
commands and run with the permissions provided by the jailbreak.
