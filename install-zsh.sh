#!/usr/bin/env bash
# Set up zsh on its own: oh-my-zsh, the zsh-autosuggestions/zsh-syntax-highlighting plugins, zsh as login shell,
# and the ~/.zshrc / ~/.zshenv symlinks. Safe to re-run. install-deps.sh runs the oh-my-zsh part too.
# Usage: ./install-zsh.sh      (DRY_RUN=1 only prints the commands; DOTFILES_OS=<os> forces the OS)
# zsh itself comes from install-deps.sh (base packages); install it first if `zsh` is missing.
set -euo pipefail
DOTFILES_DIR=$(cd -P "$(dirname "$0")" && pwd)
# shellcheck disable=SC1091
. "$DOTFILES_DIR/scripts/common.sh"

case ${1:-} in -h|--help) sed -n '2,5p' "$0"; exit 0 ;; "") ;; *) die "unknown option: $1" ;; esac

detect_os
load_os
have zsh || [ "$DRY_RUN" = 1 ] || die "zsh is not installed; run ./install-deps.sh first (or install the zsh package)."
hook os_setup          # sudo, needed for /etc/shells and chsh
install_zsh_env
ensure_login_shell
"$DOTFILES_DIR/install.sh" zsh
[ "${LOGIN_SHELL_CHANGED:-0}" = 1 ] && log "zsh is now your login shell; log out and back in for it to apply."
log "Done. Run: exec zsh"
