#!/bin/sh
# KUAL Compat Manager for Véra/KTerm.
# Numbered installer, launcher, and remover for static legacy extensions.
set -u

ROOT=/mnt/us
EXTENSIONS="$ROOT/extensions"
INBOX="$ROOT/extension-packages"
STAGING="$INBOX/.kual-compat-staging"
say() { printf '%s\n' "$*"; }
pause() { printf '\nPress Enter to continue...'; read _; }
init() { mkdir -p "$EXTENSIONS" "$INBOX" "$STAGING" || exit 1; }

archive_type() { case "$1" in *.zip) echo zip;; *.tar|*.tar.gz|*.tgz|*.tar.xz) echo tar;; *) return 1;; esac; }
archive_list() {
  case "$(archive_type "$1")" in
    zip)
      if unzip -Z1 "$1" >/dev/null 2>&1; then
        unzip -Z1 "$1"
      elif command -v zipinfo >/dev/null 2>&1; then
        zipinfo -1 "$1"
      elif command -v unzip >/dev/null 2>&1; then
        unzip -l "$1" | awk 'NR > 3 && $0 !~ /^[- ]*$/ { print $4 }'
      else
        return 2
      fi;;
    tar) tar -tf "$1";;
  esac
}
# Archive must contain one menu.json. This deliberately accepts GitHub's
# project-main/extension/menu.json wrapper as well as extension/menu.json.
extension_name() {
  archive_list "$1" | awk '
    /^\// || /(^|\/)\.\.($|\/)/ || /\/\.\// { bad=1 }
    { p=$0; sub(/^\.\//,"",p); if (p ~ /(^|\/)menu\.json$/) { sub(/\/?menu\.json$/, "", p); menus[p]=1 } }
    END { n=0; for (p in menus) {n++; chosen=p}; m=split(chosen,a,"/"); name=a[m]; if (bad || n != 1 || name !~ /^[A-Za-z0-9._-]+$/) exit 1; print name }'
}
extract() { case "$(archive_type "$1")" in zip) unzip -q "$1" -d "$2";; tar) tar -xf "$1" -C "$2";; esac; }

choose_package() {
  index="$STAGING/packages-$$"; : > "$index"; n=0
  for f in "$INBOX"/*.zip "$INBOX"/*.tar "$INBOX"/*.tar.gz "$INBOX"/*.tgz "$INBOX"/*.tar.xz; do
    [ -f "$f" ] || continue; n=$((n+1)); printf '%s\n' "$f" >> "$index"; printf '  %d) %s\n' "$n" "$(basename "$f")"
  done
  [ "$n" -gt 0 ] || { rm -f "$index"; say 'No packages found in extension-packages.'; return 1; }
  printf '\nSelect package number (Enter cancels): '; read pick
  case "$pick" in ''|*[!0-9]*) rm -f "$index"; return 1;; esac
  PICKED=$(sed -n "${pick}p" "$index"); rm -f "$index"; [ -n "$PICKED" ]
}
install() {
  say 'Packages:'; choose_package || { say 'Cancelled.'; return; }
  name=$(extension_name "$PICKED"); status=$?
  [ "$status" -eq 0 ] && [ -n "$name" ] || { say 'Rejected: the archive must contain exactly one safe extension (one menu.json).'; return; }
  case "$name" in kual-compat|kterm|.|..) say 'That extension name is reserved.'; return;; esac
  target="$EXTENSIONS/$name"; [ ! -e "$target" ] || { say "Already installed: $name"; return; }
  work="$STAGING/install-$$"; rm -rf "$work"; mkdir -p "$work" || return
  extract "$PICKED" "$work" || { rm -rf "$work"; say 'Extraction failed.'; return; }
  candidate=$(find "$work" -type f -name menu.json -print | sed -n '1p' | sed 's:/menu.json$::')
  count=$(find "$work" -type f -name menu.json | wc -l)
  [ "$count" -eq 1 ] && [ -d "$candidate" ] || { rm -rf "$work"; say 'Package layout changed; nothing installed.'; return; }
  mv "$candidate" "$target" || { rm -rf "$work"; say 'Could not install extension.'; return; }
  rm -rf "$work"; say "Installed $name. Select Launch to use it."
}

choose_extension() {
  index="$STAGING/extensions-$$"; : > "$index"; n=0
  for d in "$EXTENSIONS"/*; do
    [ -d "$d" ] || continue; base=$(basename "$d")
    [ "$base" = kual-compat ] && continue
    n=$((n+1)); printf '%s\n' "$d" >> "$index"; printf '  %d) %s\n' "$n" "$base"
  done
  [ "$n" -gt 0 ] || { rm -f "$index"; say 'No extensions found.'; return 1; }
  printf '\nSelect extension number (Enter cancels): '; read pick
  case "$pick" in ''|*[!0-9]*) rm -f "$index"; return 1;; esac
  PICKED=$(sed -n "${pick}p" "$index"); rm -f "$index"; [ -n "$PICKED" ]
}
actions() {
  # KUAL static items can span multiple JSON lines. Compact one object first.
  tr '\n{' ' \n' < "$1/menu.json" | while IFS= read -r item || [ -n "$item" ]; do
    item=$(printf '%s' "$item" | tr '\n' ' ')
    name=$(printf '%s' "$item" | awk '/"name"[ ]*:/ { s=$0; sub(/^.*"name"[ ]*:[ ]*"/,"",s); sub(/".*$/, "", s); print s }')
    act=$(printf '%s' "$item" | awk '/"action"[ ]*:/ { s=$0; sub(/^.*"action"[ ]*:[ ]*"/,"",s); sub(/".*$/, "", s); print s }')
    [ -n "$name" ] && [ -n "$act" ] && printf '%s|%s\n' "$name" "$act"
  done
}
launch() {
  say 'Extensions:'; choose_extension || { say 'Cancelled.'; return; }; dir=$PICKED
  [ -f "$dir/menu.json" ] || { say 'This extension has no menu.json actions.'; return; }
  index="$STAGING/actions-$$"; actions "$dir" > "$index"; n=$(wc -l < "$index")
  [ "$n" -gt 0 ] || { rm -f "$index"; say 'No static launch actions found.'; return; }
  say 'Actions:'; nl -ba "$index" | sed 's/|/  /'; printf '\nSelect action number (Enter cancels): '; read pick
  case "$pick" in ''|*[!0-9]*) rm -f "$index"; say 'Cancelled.'; return;; esac
  line=$(sed -n "${pick}p" "$index"); rm -f "$index"; [ -n "$line" ] || { say 'That action number does not exist.'; return; }
  label=${line%%|*}; act=${line#*|}; base=$(basename "$dir")
  case "$act" in
    "$dir"/*) rel=${act#"$dir"/};;
    "/mnt/us/extensions/$base/"*) rel=${act#"/mnt/us/extensions/$base/"};;
    *) say 'Action is outside the selected extension; rejected.'; return;;
  esac
  case "$rel" in *'..'*) say 'Unsafe action path rejected.'; return;; esac
  act=$rel
  say "Running: $label"; ( cd "$dir" && /bin/sh -c "./$act" ); say "Finished: $label"
}
remove() {
  say 'Extensions:'; choose_extension || { say 'Cancelled.'; return; }; target=$PICKED; name=$(basename "$target")
  printf 'Type DELETE to permanently remove %s: ' "$name"; read confirm
  [ "$confirm" = DELETE ] || { say 'Cancelled.'; return; }; rm -rf "$target"; say "Removed $name."
}
list_extensions() { for d in "$EXTENSIONS"/*; do [ -d "$d" ] && say "  $(basename "$d")"; done; }
list_packages() { for f in "$INBOX"/*.zip "$INBOX"/*.tar "$INBOX"/*.tar.gz "$INBOX"/*.tgz "$INBOX"/*.tar.xz; do [ -f "$f" ] && say "  $(basename "$f")"; done; }

init
while :; do
  say ''; say 'KUAL Compat Manager'; say '1) Launch an installed extension'; say '2) Install a package'; say '3) Remove an extension'; say '4) List extensions'; say '5) List package inbox'; say '6) Exit'
  printf 'Choose: '; read choice || exit 0
  case "$choice" in 1) launch;; 2) install;; 3) remove;; 4) list_extensions;; 5) list_packages;; 6) exit 0;; *) say 'Choose 1 through 6.';; esac
  [ "$choice" = 6 ] || pause
done
