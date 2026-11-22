#!/usr/bin/env bash
# Keep Zed's installed extensions and the auto_install_extensions list in
# zed/settings.json in step, 1:1, across machines.
#
#   sync-extensions.sh export [--settle]   installed -> list (run by the LaunchAgent)
#   sync-extensions.sh prune  [--dry-run]  list -> installed: remove extensions not listed
#   sync-extensions.sh adopt               list everything installed (keep extras)
#   sync-extensions.sh status              show what differs
#
# Zed installs anything on the list that's missing at startup, so additions
# need nothing from here. export carries this machine's installs and
# uninstalls into the list. It compares the installed set with the one it saw
# last time (kept outside the repo), so an extension that's on the list but not
# installed yet, after a pull, isn't mistaken for an uninstall. prune removes
# what's installed but no longer listed, which is how an uninstall on one
# machine reaches the others. Zed has no command to uninstall an extension, so
# prune deletes its folders while Zed is closed and lets Zed rebuild its index.
#
# Plain bash 3.2, awk and sort: no Python or jq needed on a fresh machine.
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}"
SETTINGS="${ZED_SYNC_SETTINGS:-$REPO/zed/settings.json}"
STATE="${ZED_SYNC_STATE:-$CONFIG/dotfiles/zed-extensions.seen}"
if [ -n "${ZED_SYNC_EXT_DIR:-}" ]; then
  EXT_DIR="$ZED_SYNC_EXT_DIR"
elif [ "$(uname)" = Darwin ]; then
  EXT_DIR="$HOME/Library/Application Support/Zed/extensions"
else
  EXT_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/zed/extensions"
fi
START='"auto_install_extensions": {'

log() { printf '%s %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*"; }

# Installed extension ids, one per line, sorted. Dev extensions are symlinks
# to local checkouts and aren't synced.
installed() {
  local d
  [ -d "$EXT_DIR/installed" ] || return 0
  for d in "$EXT_DIR/installed"/*; do
    if [ -d "$d" ] && [ ! -L "$d" ] && [ -f "$d/extension.toml" ]; then basename "$d"; fi
  done | LC_ALL=C sort -u
}

# Ids set to true in the settings block, one per line, sorted.
listed() {
  awk -v start="$START" '
    index($0, start) { inside = 1; next }
    inside && /^[[:space:]]*}/ { exit }
    inside && match($0, /"[^"]+"[[:space:]]*:[[:space:]]*true/) {
      s = substr($0, RSTART + 1); print substr(s, 1, index(s, "\"") - 1)
    }' "$SETTINGS" | LC_ALL=C sort -u
}

has_block() { grep -qF "$START" "$SETTINGS"; }

# Replace the block's entries with the ids on stdin. Writes only on a change,
# and in place, so the symlink and Zed's file watcher both stay happy.
write_list() {
  local tmp
  tmp="$(mktemp "${TMPDIR:-/tmp}/zed-settings.XXXXXX")"
  # macOS awk can't take a multi-line -v value, so the ids go in via ENVIRON.
  if ! IDS="$(cat)" awk -v start="$START" '
    index($0, start) {
      print; inside = 1
      indent = $0; sub(/[^[:space:]].*/, "", indent)
      n = split(ENVIRON["IDS"], a, "\n")
      for (i = 1; i <= n; i++) if (a[i] != "") printf "%s  \"%s\": true,\n", indent, a[i]
      next
    }
    inside && /^[[:space:]]*}/ { inside = 0 }
    inside { next }
    { print }' "$SETTINGS" > "$tmp"; then
    rm -f "$tmp"; log "failed to rewrite $SETTINGS, left it unchanged" >&2; return 2
  fi
  # Never write something that lost the block or most of the file.
  if ! grep -qF "$START" "$tmp" || [ "$(wc -l < "$tmp")" -lt "$(( $(wc -l < "$SETTINGS") / 2 ))" ]; then
    rm -f "$tmp"; log "rewrite of $SETTINGS looked wrong, left it unchanged" >&2; return 2
  fi
  if cmp -s "$tmp" "$SETTINGS"; then
    rm -f "$tmp"
    return 1
  fi
  cat "$tmp" > "$SETTINGS"
  rm -f "$tmp"
}

cmd_export() {
  [ "${1:-}" = --settle ] && sleep 3   # let Zed finish an install or upgrade
  [ -d "$EXT_DIR/installed" ] || { log "no Zed extensions folder yet, nothing to export"; return 0; }
  has_block || { log "no auto_install_extensions block in $SETTINGS" >&2; return 1; }

  local now seen added removed list next
  now="$(installed)"
  # First run on a machine: treat everything installed as newly added, so
  # this machine's extensions join the list and nothing is dropped.
  if [ -f "$STATE" ]; then seen="$(cat "$STATE")"; else seen=""; fi
  added="$(LC_ALL=C comm -13 <(printf '%s\n' "$seen" | sed '/^$/d') <(printf '%s\n' "$now" | sed '/^$/d'))"
  removed="$(LC_ALL=C comm -23 <(printf '%s\n' "$seen" | sed '/^$/d') <(printf '%s\n' "$now" | sed '/^$/d'))"
  list="$(listed)"
  next="$(printf '%s\n%s\n' "$list" "$added" | sed '/^$/d' | LC_ALL=C sort -u \
    | LC_ALL=C comm -23 - <(printf '%s\n' "$removed" | sed '/^$/d'))"

  local rc=0
  printf '%s\n' "$next" | write_list || rc=$?
  [ "$rc" -ne 2 ] || return 1
  if [ "$rc" -eq 0 ]; then
    [ -z "$added" ]   || log "listed: $(printf '%s' "$added" | tr '\n' ' ')"
    [ -z "$removed" ] || log "unlisted: $(printf '%s' "$removed" | tr '\n' ' ')"
  fi
  mkdir -p "$(dirname "$STATE")"
  printf '%s\n' "$now" | sed '/^$/d' > "$STATE"
}

zed_running() { [ "${ZED_SYNC_IGNORE_RUNNING:-0}" = 1 ] && return 1; pgrep -x zed >/dev/null 2>&1; }

# Installed but not listed, one per line.
extras() { LC_ALL=C comm -23 <(installed) <(listed); }

cmd_prune() {
  local dry=0 id gone=""
  [ "${1:-}" = --dry-run ] && dry=1
  has_block || { echo "no auto_install_extensions block in $SETTINGS" >&2; return 1; }
  local list; list="$(extras)"
  [ -n "$list" ] || return 0
  if [ "$dry" -eq 1 ]; then
    for id in $list; do echo "would   remove Zed extension $id"; done
    return 0
  fi
  if zed_running; then
    echo "warn    Zed is running; close it and re-run to remove: $(printf '%s' "$list" | tr '\n' ' ')"
    return 0
  fi
  for id in $list; do
    rm -rf "$EXT_DIR/installed/$id" "$EXT_DIR/work/$id"
    echo "remove  Zed extension $id"
    gone=1
  done
  # The index is a cache of installed/; Zed rebuilds it on the next start.
  [ -z "$gone" ] || rm -f "$EXT_DIR/index.json"
  mkdir -p "$(dirname "$STATE")"
  installed > "$STATE"
}

# Keep what's installed here but unlisted, by listing it again.
cmd_adopt() {
  local list; list="$(extras)"
  [ -n "$list" ] || return 0
  printf '%s\n%s\n' "$(listed)" "$list" | sed '/^$/d' | LC_ALL=C sort -u | write_list || true
  echo "keep    Zed extensions $(printf '%s' "$list" | tr '\n' ' ')"
}

cmd_status() {
  echo "Listed but not installed (Zed installs these on startup):"
  LC_ALL=C comm -13 <(installed) <(listed) | sed 's/^/  /'
  echo "Installed but not listed (prune removes these):"
  extras | sed 's/^/  /'
}

case "${1:-}" in
  export) shift; cmd_export "$@" ;;
  prune)  shift; cmd_prune "$@" ;;
  adopt)  cmd_adopt ;;
  status) cmd_status ;;
  extras) extras ;;
  *)      sed -n '2,9p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'; exit 2 ;;
esac
