#!/bin/sh
# KUAL Compat: a deliberately small, KPM-native bridge for trusted legacy
# KUAL extensions. It never writes /opt or appreg.db.

set -eu

EXTENSIONS_DIR="${KUAL_COMPAT_EXTENSIONS_DIR:-/mnt/us/extensions}"
SELF_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
INDEX_FILE="${SELF_DIR}/.menu-index"

usage() {
    cat <<'EOF'
KUAL Compat (KPM-native)

Commands:
  ;kpm --fbink launch kual-compat list
      List legacy KUAL extensions and their runnable menu items.

  ;kpm --fbink launch kual-compat run <extension-folder> <item-number>
      Run one listed action. Only install extensions you trust.

  ;kpm --fbink launch kual-compat refresh
      Rebuild the menu index.

This compatibility runner does not install the legacy Java KUAL Booklet.
EOF
}

build_index() {
    : > "$INDEX_FILE"
    [ -d "$EXTENSIONS_DIR" ] || return 0

    for menu in "$EXTENSIONS_DIR"/*/menu.json; do
        [ -f "$menu" ] || continue
        extension=$(basename "$(dirname "$menu")")
        # Legacy KUAL menu files are JSON. This intentionally accepts the
        # common one-object-per-line layout and extracts items with both a
        # name and action. Complex/dynamic menus remain unsupported for now.
        awk -v extension="$extension" '
            function value(key,    re, text) {
                re = "\\\"" key "\\\"[[:space:]]*:[[:space:]]*\\\"[^\\\"]*\\\""
                if (match($0, re)) {
                    text = substr($0, RSTART, RLENGTH)
                    sub("^[^:]*:[[:space:]]*\\\"", "", text)
                    sub("\\\"$", "", text)
                    return text
                }
                return ""
            }
            {
                name = value("name")
                action = value("action")
                param = value("param")
                if (name != "" && action != "")
                    print extension "\t" name "\t" action "\t" param
            }
        ' "$menu" >> "$INDEX_FILE"
    done
}

list_items() {
    build_index
    if [ ! -s "$INDEX_FILE" ]; then
        echo "No compatible legacy KUAL menu actions were found in $EXTENSIONS_DIR."
        return 0
    fi

    current=""
    item=0
    while IFS="$(printf '\t')" read -r extension name action param; do
        if [ "$extension" != "$current" ]; then
            current="$extension"
            item=0
            printf '\n[%s]\n' "$extension"
        fi
        item=$((item + 1))
        printf '  %s. %s\n' "$item" "$name"
    done < "$INDEX_FILE"
    printf '\nRun: ;kpm --fbink launch kual-compat run <extension-folder> <item-number>\n'
}

run_item() {
    [ "$#" -eq 2 ] || { usage; return 2; }
    extension="$1"
    wanted="$2"
    case "$wanted" in *[!0-9]*|'') echo "Item number must be a positive integer."; return 2;; esac

    build_index
    line=$(awk -F '\t' -v extension="$extension" -v wanted="$wanted" '
        $1 == extension { seen++; if (seen == wanted) { print; exit } }
    ' "$INDEX_FILE")
    [ -n "$line" ] || { echo "No such action: $extension #$wanted"; return 2; }

    action=$(printf '%s\n' "$line" | awk -F '\t' '{print $3}')
    param=$(printf '%s\n' "$line" | awk -F '\t' '{print $4}')
    extension_dir="$EXTENSIONS_DIR/$extension"
    [ -d "$extension_dir" ] || { echo "Extension directory disappeared: $extension"; return 1; }

    echo "Running $extension #$wanted."
    echo "Only run extensions from sources you trust."
    cd "$extension_dir"
    if [ -n "$param" ]; then
        sh -c "$action \"\$1\"" sh "$param"
    else
        sh -c "$action"
    fi
}

command=${1:-list}
case "$command" in
    list|refresh) list_items ;;
    run) shift; run_item "$@" ;;
    help|-h|--help) usage ;;
    *) echo "Unknown command: $command"; usage; exit 2 ;;
esac
