# KUAL Compat Manager (Véra / firmware 5.19.4+)

KUAL Compat Manager is a direct Véra scriptlet that opens in KTerm. It manages
local legacy KUAL extension archives without using KPM or modifying Kindle
system files.

## Install KUAL Compat Manager

Copy these two items to your Kindle:

```text
scriptlets/KUAL Compat.sh  -> documents/KUAL Compat.sh
manager/manage.sh          -> extensions/kual-compat/bin/manage.sh
```

KTerm must be installed at `extensions/kterm/`. Tap **KUAL Compat** in the
Kindle Library to open the manager in KTerm.

## Install an extension archive

1. Copy a `.zip`, `.tar`, `.tar.gz`, `.tgz`, or `.tar.xz` archive into the
   root-level `extension-packages/` folder.
2. Open **KUAL Compat** and select **3) Install a package**.
3. Type the archive's exact filename.

The archive must contain exactly one extension directory, in either form:

```text
extension-name/menu.json
```

or:

```text
extensions/extension-name/menu.json
```

The manager rejects absolute paths and path-traversal entries, never overwrites
an existing extension, and extracts only into `extensions/`.

## Remove an extension

Select **4) Remove an installed extension**, enter its folder name, then type
`DELETE` exactly. The archive in `extension-packages/` is retained.

## Limitations

- This handles common static legacy extension layouts; it does not make legacy
  Java, GTK, ARM, or device-specific applications compatible.
- ZIP installation requires `unzip` or `zipinfo` on the Kindle. If unavailable,
  use a `.tar` archive or unpack the ZIP on a computer.
- Install and run extensions only from sources you trust; extension actions are
  shell commands and may run with jailbreak privileges.
