#!/bin/sh
set -eu

DOCUMENT="/mnt/us/documents/KUAL Compat.sh"
cat > "$DOCUMENT" <<'EOF'
#!/bin/sh
# Name: KUAL Compat
# Author: KUAL Compat contributors
# DontUseFBInk

kpm --fbink launch kual-compat list
EOF
chmod 755 "$DOCUMENT"
echo "Installed KUAL Compat scriptlet in documents/."
