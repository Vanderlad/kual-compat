#!/bin/sh
# Name: KUAL Compat
# Author: KUAL Compat contributors
#
# Direct Véra scriptlet. Lists common static legacy KUAL menu actions found in
# /mnt/us/extensions. It does not use the removed Java KUAL Booklet.

set -eu

EXTENSIONS_DIR="/mnt/us/extensions"

echo "KUAL Compat"
echo ""

if [ ! -d "$EXTENSIONS_DIR" ]; then
    echo "No extensions folder found."
    echo "Create /mnt/us/extensions and add a trusted legacy extension."
    exit 0
fi

found=0
for menu in "$EXTENSIONS_DIR"/*/menu.json; do
    [ -f "$menu" ] || continue
    extension=$(basename "$(dirname "$menu")")
    actions=$(awk '
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
            if (name != "" && action != "") print name
        }
    ' "$menu")
    [ -n "$actions" ] || continue
    found=1
    echo "[$extension]"
    printf '%s\n' "$actions" | awk '{ printf "  - %s\n", $0 }'
    echo ""
done

if [ "$found" -eq 0 ]; then
    echo "No compatible static legacy KUAL menu actions found."
    echo ""
    echo "This is expected until an extension is copied to extensions/."
else
    echo "This script lists actions only."
    echo "Run legacy actions only when you trust their source."
fi
