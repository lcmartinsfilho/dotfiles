#!/usr/bin/env bash
# Install Niri and its dependencies, then symlink its config (.config/niri/*) into $HOME. Safe to re-run.
# Usage: ./install-niri.sh [--deps-only|--links-only]   (DRY_RUN=1 only prints the commands)
# Niri is optional, so ./install.sh and ./install-deps.sh deliberately leave it alone.
# Currently Fedora only (scripts/os/<os>.sh must define os_install_niri).
set -euo pipefail

DOTFILES_DIR=$(cd -P "$(dirname "$0")" && pwd)
# shellcheck disable=SC1091
. "$DOTFILES_DIR/scripts/common.sh"

DEPS=1 LINKS=1
case "${1:-}" in
  "") ;;
  --deps-only) LINKS=0 ;;
  --links-only) DEPS=0 ;;
  -h|--help) sed -n '2,5p' "$0"; exit 0 ;;
  *) die "unknown option: $1" ;;
esac

link_niri() {
  local f bak
  cd "$DOTFILES_DIR"
  git ls-files .config/niri | while read -r f; do
    run mkdir -p "$HOME/$(dirname "$f")"
    [ "$(cd -P "$(dirname "$HOME/$f")" && pwd)/$(basename "$f")" = "$PWD/$f" ] && continue
    if [ -e "$HOME/$f" ] && [ ! -L "$HOME/$f" ]; then
      bak="$HOME/$f.bak"
      [ -e "$bak" ] && bak="$bak.$(date +%s)"
      run mv "$HOME/$f" "$bak"
    fi
    run ln -sfn "$PWD/$f" "$HOME/$f"
  done
  run mkdir -p "$HOME/Pictures/Screenshots"
}

detect_os
load_os
declare -F os_install_niri >/dev/null || die "Niri install is not supported on $OS yet (add os_install_niri to scripts/os/$OS.sh)"

if [ "$DEPS" = 1 ]; then
  log "Installing Niri ($OS)"
  hook os_setup
  os_install_niri
  [ ${#MISSING[@]} -eq 0 ] || warn "packages that failed to install: ${MISSING[*]}"
fi
if [ "$LINKS" = 1 ]; then
  log "Linking Niri config"
  link_niri
fi
echo
log "Done. Pick the 'Niri' session at the login screen. (The sway config is untouched.)"
