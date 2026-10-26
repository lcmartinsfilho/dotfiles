#!/usr/bin/env bash
# Install the tools these dotfiles depend on for the current OS (Fedora, Ubuntu/Debian, macOS, FreeBSD). Safe to re-run.
# Usage: ./install-deps.sh [--gui]      (DRY_RUN=1 only prints the commands; DOTFILES_OS=<os> forces the OS)
#   --gui  also install sway, waybar, wofi, rofi, alacritty, fonts and the Breeze GTK theme (not on macOS)
# Then run ./install.sh to symlink the dotfiles. Per-OS steps live in scripts/os/<os>.sh;
# steps shared by every OS live in scripts/common.sh. LSPs/formatters/debuggers are installed
# by mason on the first nvim launch (on FreeBSD, which has no mason binaries, from pkg/npm instead).
set -euo pipefail

DOTFILES_DIR=$(cd -P "$(dirname "$0")" && pwd)
# shellcheck disable=SC1091
. "$DOTFILES_DIR/scripts/common.sh"

for a in "$@"; do
  case $a in
    --gui) GUI=1 ;;
    -h|--help) sed -n '2,7p' "$0"; exit 0 ;;
    *) die "unknown option: $a" ;;
  esac
done

detect_os
load_os
log "Installing dependencies ($OS)"

hook os_setup
hook os_install_prepare
run mkdir -p "$BIN" "$HOME/.local/opt"
case ":$PATH:" in *":$BIN:"*) ;; *) export PATH="$BIN:$PATH" ;; esac

hook os_install_base
install_rust
hook os_install_tools
install_omz
[ "${OS_NODE:-nvm}" = nvm ] && install_nvm_node
hook os_install_agents
if [ "$GUI" = 1 ]; then
  if declare -F os_install_gui >/dev/null; then log "Installing desktop packages"; os_install_gui
  else warn "--gui: no desktop packages for $OS"; fi
fi

ensure_login_shell
echo
log "Done. Next: ./install.sh."
[ "${LOGIN_SHELL_CHANGED:-0}" = 1 ] && log "zsh is now your login shell; log out and back in (a new terminal window is not enough) for it to apply."
[ ${#MISSING[@]} -eq 0 ] || warn "packages that failed to install: ${MISSING[*]}"
if [ "$GUI" != 1 ] && declare -F os_install_gui >/dev/null; then
  echo "Desktop pieces (sway/waybar/wofi/alacritty/fonts) were skipped; re-run with --gui to install them."
fi
hook os_install_notes
