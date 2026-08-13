#!/bin/sh
# KUAL Compat Manager for Véra/KTerm.
# Manages local legacy-extension archives without writing to system locations.

set -u

ROOT=/mnt/us
EXTENSIONS="$ROOT/extensions"
INBOX="$ROOT/extension-packages"
STAGING="$INBOX/.kual-compat-staging"

say() { printf '%s\n' "$*"; }
pause() { printf '\nPress Enter to continue...'; read _unused; }

init_dirs() {
    mkdir -p "$EXTENSIONS" "$INBOX" "$STAGING" || {
        say 'Could not create KUAL Compat folders.'; exit 1;
    }
}

list_extensions() {
    say 'Installed extensions:'
    found=0
    for dir in "$EXTENSIONS"/*; do
        [ -d "$dir" ] || continue
        found=1
        name=$(basename "$dir")
        if [ -f "$dir/menu.json" ]; then
            say "  $name (menu.json found)"
        else
            say "  $name (no menu.json)"
        fi
    done
    [ "$found" -eq 1 ] || say '  None.'
}

list_packages() {
    say 'Packages waiting in extension-packages:'
    found=0
    for file in "$INBOX"/*.zip "$INBOX"/*.tar "$INBOX"/*.tar.gz "$INBOX"/*.tgz "$INBOX"/*.tar.xz; do
        [ -f "$file" ] || continue
        found=1
        say "  $(basename "$file")"
    done
    [ "$found" -eq 1 ] || say '  None.'
}

archive_type() {
    case "$1" in
        *.zip) printf '%s' zip ;;
        *.tar|*.tar.gz|*.tgz|*.tar.xz) printf '%s' tar ;;
        *) return 1 ;;
    esac
}

archive_list() {
    case "$(archive_type "$1")" in
        zip)
            if command -v unzip >/dev/null 2>&1; then
                unzip -Z1 "$1"
            elif command -v zipinfo >/dev/null 2>&1; then
                zipinfo -1 "$1"
            else
                return 2
            fi
            ;;
        tar) tar -tf "$1" ;;
    esac
}

safe_member_list() {
    # Reject absolute paths, traversal, and archives that do not contain a
    # single extension directory. A package may be rooted at extensions/name/
    # or directly at name/.
    archive_list "$1" | awk '
        /^\// || /(^|\/)\.\.($|\/)/ || /\/\.\// { bad=1 }
        {
          p=$0
          sub(/^\.\//, "", p)
          if (p ~ /^extensions\//) sub(/^extensions\//, "", p)
          split(p, a, "/")
          if (a[1] != "") roots[a[1]]=1
        }
        END {
          n=0; for (root in roots) { n++; chosen=root }
          if (bad || n != 1 || chosen !~ /^[A-Za-z0-9._-]+$/) exit 1
          print chosen
        }
    '
}

extract_archive() {
    case "$(archive_type "$1")" in
        zip) unzip -q "$1" -d "$2" ;;
        tar) tar -xf "$1" -C "$2" ;;
    esac
}

install_package() {
    list_packages
    printf '\nType the exact package filename to install (or press Enter to cancel): '
    read package
    [ -n "$package" ] || return 0
    case "$package" in
        */*|.*) say 'Invalid package name.'; return 0 ;;
    esac
    source="$INBOX/$package"
    [ -f "$source" ] || { say 'Package not found.'; return 0; }
    archive_type "$source" >/dev/null || { say 'Supported formats: .zip, .tar, .tar.gz, .tgz, .tar.xz'; return 0; }

    extension=$(safe_member_list "$source")
    status=$?
    if [ "$status" -eq 2 ]; then
        say 'This Kindle does not have an unzip utility available for ZIP packages.'
        say 'Use a .tar archive, or unpack the ZIP on your computer.'
        return 0
    fi
    [ "$status" -eq 0 ] && [ -n "$extension" ] || {
        say 'Rejected: package must contain exactly one safe extension folder.'
        return 0
    }

    case "$extension" in kual-compat|.|..) say 'That extension name is reserved.'; return 0;; esac
    target="$EXTENSIONS/$extension"
    [ ! -e "$target" ] || { say "Already installed: $extension"; return 0; }

    work="$STAGING/$extension-$$"
    rm -rf "$work"
    mkdir -p "$work" || return 1
    if ! extract_archive "$source" "$work"; then
        rm -rf "$work"
        say 'Extraction failed; nothing was installed.'
        return 0
    fi

    candidate="$work/$extension"
    [ -d "$candidate" ] || candidate="$work/extensions/$extension"
    if [ ! -d "$candidate" ]; then
        rm -rf "$work"
        say 'Extraction layout did not match the validated package; nothing was installed.'
        return 0
    fi

    mv "$candidate" "$target" || { rm -rf "$work"; say 'Could not install extension.'; return 0; }
    rm -rf "$work"
    say "Installed $extension into extensions/."
    if [ ! -f "$target/menu.json" ]; then
        say 'Note: this folder has no menu.json, so it may not be a legacy KUAL extension.'
    fi
}

remove_extension() {
    list_extensions
    printf '\nType an extension folder name to remove (or press Enter to cancel): '
    read extension
    [ -n "$extension" ] || return 0
    case "$extension" in *[!A-Za-z0-9._-]*|'') say 'Invalid extension name.'; return 0;; esac
    target="$EXTENSIONS/$extension"
    [ -d "$target" ] || { say 'Extension folder not found.'; return 0; }
    printf 'Type DELETE to permanently remove %s: ' "$extension"
    read confirmation
    [ "$confirmation" = DELETE ] || { say 'Cancelled.'; return 0; }
    rm -rf "$target"
    say "Removed $extension."
}

init_dirs
while :; do
    say ''
    say 'KUAL Compat Manager'
    say '1) List installed extensions'
    say '2) List package inbox'
    say '3) Install a package from extension-packages'
    say '4) Remove an installed extension'
    say '5) Exit'
    printf 'Choose: '
    read choice || exit 0
    case "$choice" in
        1) list_extensions; pause ;;
        2) list_packages; pause ;;
        3) install_package; pause ;;
        4) remove_extension; pause ;;
        5) exit 0 ;;
        *) say 'Choose 1 through 5.'; pause ;;
    esac
done
