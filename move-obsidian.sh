#!/usr/bin/env bash
# OPTIONAL: move an Obsidian vault and keep Obsidian + LiveSync pointing at it.
# Usage: ./move-obsidian.sh [--list FILE] [SRC [DEST]]     (DRY_RUN=1 only prints the commands)
#        SRC  vault to move   (default ~/lcm-local)       DEST  new vault path (default ~/Obsidian/lcm)
# Does: refuses while Obsidian is running; mv (same filesystem, never overwrites); backs up and repoints the
# vault path in Obsidian's obsidian.json (Flatpak or native); backs up the LiveSync data.json and rewrites any
# stale absolute vault path in it; --list FILE then moves that file into the vault (never overwrites).
# Re-run safe: nothing to do once DEST exists and SRC is gone.
# Deliberately NOT run by ./install.sh, ./install-deps.sh or ./update.sh.
set -euo pipefail
DOTFILES_DIR=$(cd -P "$(dirname "$0")" && pwd)
# shellcheck disable=SC1091
. "$DOTFILES_DIR/scripts/common.sh"
LS=.obsidian/plugins/obsidian-livesync/data.json
LIST=""
while [ $# -gt 0 ]; do
  case "$1" in
    --list) [ $# -ge 2 ] || die "--list needs a FILE"; LIST=$2; shift 2 ;;
    -h|--help) sed -n '2,9p' "$0"; exit 0 ;;
    -*) die "unknown option: $1" ;;
    *) break ;;
  esac
done
[ $# -le 2 ] || die "too many arguments (see --help)"
OLD=${1:-$HOME/lcm-local}
NEW=${2:-$HOME/Obsidian/lcm}
OLD=${OLD/#\~/$HOME}; NEW=${NEW/#\~/$HOME}
OLD=${OLD%/}; NEW=${NEW%/}
[ -z "$LIST" ] || [ -f "$LIST" ] || die "not a file: $LIST"

if pgrep -x -i obsidian >/dev/null 2>&1 || { have flatpak && flatpak ps --columns=application 2>/dev/null | grep -qx 'md.obsidian.Obsidian'; }; then
  [ "$DRY_RUN" = 1 ] && warn "Obsidian is running (ignored in DRY_RUN)" || die "close Obsidian first"
fi

log "Moving the vault"
if [ -d "$OLD" ] && [ ! -e "$NEW" ]; then
  run mkdir -p "$(dirname "$NEW")"
  run mv -n -- "$OLD" "$NEW"
elif [ -d "$NEW" ] && [ ! -e "$OLD" ]; then
  echo "already at $NEW"
else
  die "expected exactly one of $OLD / $NEW to exist"
fi

log "Obsidian vault registry"
for f in "$HOME/.var/app/md.obsidian.Obsidian/config/obsidian/obsidian.json" "$HOME/.config/obsidian/obsidian.json"; do
  [ -f "$f" ] || continue
  grep -q "$OLD" "$f" || { echo "$f: nothing to change"; continue; }
  if [ "$DRY_RUN" = 1 ]; then echo "+ repoint $f: $OLD -> $NEW"; else
    cp -n -- "$f" "$f.bak-move"
    python3 -I - "$f" "$OLD" "$NEW" <<'PY'
import json, sys
f, old, new = sys.argv[1:4]
d = json.load(open(f))
for v in d.get("vaults", {}).values():
    if v.get("path") == old:
        v["path"] = new
json.dump(d, open(f, "w"), separators=(",", ":"))
PY
    echo "$f: repointed (backup: $f.bak-move)"
  fi
done

log "LiveSync settings"
D=$NEW/$LS
[ "$DRY_RUN" = 1 ] && [ ! -f "$D" ] && D=$OLD/$LS
if [ -f "$D" ] && grep -q "$OLD" "$D"; then
  if [ "$DRY_RUN" = 1 ]; then echo "+ rewrite $OLD -> $NEW in $D"; else
    cp -n -- "$D" "$D.bak-move"
    python3 -I - "$D" "$OLD" "$NEW" <<'PY'
import sys
f, old, new = sys.argv[1:4]
s = open(f).read()
open(f, "w").write(s.replace(old, new))
PY
    echo "rewrote the old path in $D (backup: $D.bak-move)"
  fi
else
  echo "no absolute vault path in the LiveSync config, nothing to change"
fi
warn "the vault is now named '$(basename "$NEW")': LiveSync names its local database after the vault, so on the next start it"
warn "creates a fresh local DB. Expect a one-time re-sync; if it asks, choose 'Fetch from remote' (files are kept)."

if [ -n "$LIST" ]; then
  log "Moving $LIST into the vault"
  t=$NEW/$(basename "$LIST")
  if [ -e "$t" ]; then warn "already exists, skipping: $t"; else run mv -n -- "$LIST" "$t"; fi
fi
