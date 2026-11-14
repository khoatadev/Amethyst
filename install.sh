#!/usr/bin/env bash
# Luminous — deploy config Hyprland + Kitty vào ~/.config
# Backup file cũ thành *.bak.<timestamp> trước khi đè.

set -euo pipefail

REPO="$(cd "$(dirname "$0")" && pwd)"
DEST="$HOME/.config"
STAMP="$(date +%Y%m%d%H%M%S)"

backup() {
    local app="$1" f="$2" dst="$DEST/$app/${f#./}"
    if [[ -e "$dst" ]]; then
        mv "$dst" "$dst.bak.$STAMP"
        echo "backup: $dst -> $dst.bak.$STAMP"
    fi
}

for app in hypr kitty; do
    mkdir -p "$DEST/$app"
    while IFS= read -r f; do
        backup "$app" "$f"
    done < <(cd "$REPO/.config/$app" && find . -type f)
    cp -r "$REPO/.config/$app" "$DEST/"
    echo "installed: $DEST/$app"
done

echo "Xong. File cũ (nếu có) được backup thành *.bak.$STAMP."
