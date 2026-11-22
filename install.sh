#!/usr/bin/env bash
# Symlink these configs into place. Everything is enabled by default; an
# interactive wizard lets you opt out of individual tools.
#
#   ./install.sh                 wizard (asks per tool, default yes)
#   ./install.sh --yes           no prompts, install everything (or the saved choices)
#   ./install.sh --skip herdr    skip one or more tools (comma separated)
#   ./install.sh --only ghostty  install only the listed tools
#   ./install.sh --dry-run       show what would happen, change nothing
#   ./install.sh --list          list the tools
#
# Safe to re-run. Existing real files are moved to <name>.bak.<timestamp>
# before linking. Choices are remembered in $XDG_CONFIG_HOME/dotfiles/choices
# (outside the repo) and become the wizard's defaults next time.
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}"
CHOICES="$CONFIG/dotfiles/choices"
STAMP="$(date +%Y%m%d%H%M%S)"
OS="$(uname)"

# Tools: name|description. Order is the order of the wizard.
TOOLS="ghostty|Ghostty terminal config and Gruvbox Sepia themes
herdr|Herdr config
zed|Zed settings and keymap"

tool_names() { printf '%s\n' "$TOOLS" | cut -d'|' -f1; }
tool_desc()  { printf '%s\n' "$TOOLS" | awk -F'|' -v t="$1" '$1 == t { print $2 }'; }
is_tool()    { tool_names | grep -qx "$1"; }

# Selection is stored as one variable per tool: SEL_<name>=on|off
sel_get() { eval "printf '%s' \"\${SEL_$1:-on}\""; }
sel_set() { eval "SEL_$1=$2"; }

usage() { sed -n '2,13p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'; }

DRY_RUN=0
ASSUME_YES=0
ONLY=""
SKIP=""

while [ $# -gt 0 ]; do
  case "$1" in
    -y|--yes)     ASSUME_YES=1 ;;
    -n|--dry-run) DRY_RUN=1 ;;
    --only)       [ $# -ge 2 ] || { echo "--only needs a value" >&2; exit 2; }; ONLY="$2"; shift ;;
    --skip)       [ $# -ge 2 ] || { echo "--skip needs a value" >&2; exit 2; }; SKIP="$2"; shift ;;
    --only=*)     ONLY="${1#*=}" ;;
    --skip=*)     SKIP="${1#*=}" ;;
    -l|--list)    tool_names | while read -r t; do printf '%-8s %s\n' "$t" "$(tool_desc "$t")"; done; exit 0 ;;
    -h|--help)    usage; exit 0 ;;
    *)            echo "Unknown option: $1" >&2; usage >&2; exit 2 ;;
  esac
  shift
done

validate_list() {
  local item
  for item in $(printf '%s' "$1" | tr ',' ' '); do
    is_tool "$item" || { echo "Unknown tool: $item (see --list)" >&2; exit 2; }
  done
}
[ -n "$ONLY" ] && validate_list "$ONLY"
[ -n "$SKIP" ] && validate_list "$SKIP"

# --- Defaults: all on, then overridden by previously saved choices ----------
if [ -f "$CHOICES" ]; then
  while IFS='=' read -r key val; do
    if is_tool "$key" 2>/dev/null && { [ "$val" = on ] || [ "$val" = off ]; }; then
      sel_set "$key" "$val"
    fi
  done < "$CHOICES"
fi

# --- Flags override everything ----------------------------------------------
FLAGGED=0
if [ -n "$ONLY" ]; then
  FLAGGED=1
  for t in $(tool_names); do sel_set "$t" off; done
  for t in $(printf '%s' "$ONLY" | tr ',' ' '); do sel_set "$t" on; done
fi
if [ -n "$SKIP" ]; then
  FLAGGED=1
  for t in $(printf '%s' "$SKIP" | tr ',' ' '); do sel_set "$t" off; done
fi

# --- Wizard (only when interactive and nothing was decided by flags) --------
if [ "$ASSUME_YES" -eq 0 ] && [ "$FLAGGED" -eq 0 ] && [ -t 0 ] && [ -t 1 ]; then
  echo "Dotfiles setup: press Enter to accept the default shown in brackets."
  echo
  for t in $(tool_names); do
    current="$(sel_get "$t")"
    if [ "$current" = on ]; then prompt="[Y/n]"; else prompt="[y/N]"; fi
    while true; do
      read -r -p "Install $(tool_desc "$t")? $prompt " ans || ans=""
      case "$ans" in
        "")        break ;;
        [Yy]*)     current=on;  break ;;
        [Nn]*)     current=off; break ;;
        *)         echo "  Please answer y or n." ;;
      esac
    done
    sel_set "$t" "$current"
  done
  echo
fi

# --- Linking ----------------------------------------------------------------
link() {
  local src="$1" dest="$2"
  if [ -L "$dest" ] && [ "$(readlink "$dest")" = "$src" ]; then
    echo "ok      $dest"
    return
  fi
  if [ "$DRY_RUN" -eq 1 ]; then
    echo "would   link $dest -> $src"
    return
  fi
  mkdir -p "$(dirname "$dest")"
  if [ -e "$dest" ] || [ -L "$dest" ]; then
    mv "$dest" "$dest.bak.$STAMP"
    echo "backup  $dest -> $dest.bak.$STAMP"
  fi
  ln -s "$src" "$dest"
  echo "link    $dest -> $src"
}

install_ghostty() {
  # Ghostty reads $XDG_CONFIG_HOME/ghostty on macOS and Linux (macOS also reads
  # ~/Library/Application Support/com.mitchellh.ghostty, which we leave unused).
  link "$REPO/ghostty/config.ghostty" "$CONFIG/ghostty/config.ghostty"
  local theme
  for theme in "$REPO"/ghostty/themes/*; do
    link "$theme" "$CONFIG/ghostty/themes/$(basename "$theme")"
  done
  # A leftover macOS-path config is loaded as well and could override the link.
  local mac_cfg="$HOME/Library/Application Support/com.mitchellh.ghostty/config.ghostty"
  if [ "$OS" = Darwin ] && [ -e "$mac_cfg" ] && [ ! -L "$mac_cfg" ]; then
    echo "warn    $mac_cfg also exists and is loaded too; remove it if it differs."
  fi
}

install_herdr() {
  link "$REPO/herdr/config.toml" "$CONFIG/herdr/config.toml"
}

install_zed() {
  # Zed reads ~/.config/zed on macOS and $XDG_CONFIG_HOME/zed on Linux. Only the
  # two JSON files are linked; prompts/ is a local database and stays out.
  link "$REPO/zed/settings.json" "$CONFIG/zed/settings.json"
  link "$REPO/zed/keymap.json" "$CONFIG/zed/keymap.json"
}

for t in $(tool_names); do
  if [ "$(sel_get "$t")" = on ]; then
    echo "== $t"
    "install_$t"
  else
    echo "skip    $t"
  fi
done

# --- Remember the choices for next time -------------------------------------
if [ "$DRY_RUN" -eq 0 ]; then
  mkdir -p "$(dirname "$CHOICES")"
  for t in $(tool_names); do printf '%s=%s\n' "$t" "$(sel_get "$t")"; done > "$CHOICES"
fi
