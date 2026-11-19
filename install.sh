#!/usr/bin/env bash
# Symlink these configs into place. Safe to re-run; existing real files are
# moved to <name>.bak.<timestamp> before linking.
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}"
STAMP="$(date +%Y%m%d%H%M%S)"

link() {
  local src="$1" dest="$2"
  mkdir -p "$(dirname "$dest")"
  if [ -L "$dest" ] && [ "$(readlink "$dest")" = "$src" ]; then
    echo "ok      $dest"
    return
  fi
  if [ -e "$dest" ] || [ -L "$dest" ]; then
    mv "$dest" "$dest.bak.$STAMP"
    echo "backup  $dest -> $dest.bak.$STAMP"
  fi
  ln -s "$src" "$dest"
  echo "link    $dest -> $src"
}

# Ghostty reads $XDG_CONFIG_HOME/ghostty on macOS and Linux (macOS also reads
# ~/Library/Application Support/com.mitchellh.ghostty, which we leave unused).
link "$REPO/ghostty/config.ghostty" "$CONFIG/ghostty/config.ghostty"
for theme in "$REPO"/ghostty/themes/*; do
  link "$theme" "$CONFIG/ghostty/themes/$(basename "$theme")"
done

# Herdr
link "$REPO/herdr/config.toml" "$CONFIG/herdr/config.toml"

# A leftover macOS-path Ghostty config would be loaded as well and could
# override the linked one, so warn about it.
MAC_CFG="$HOME/Library/Application Support/com.mitchellh.ghostty/config.ghostty"
if [ "$(uname)" = "Darwin" ] && [ -e "$MAC_CFG" ] && [ ! -L "$MAC_CFG" ]; then
  echo "warn    $MAC_CFG also exists and is loaded too; remove it if it differs."
fi
