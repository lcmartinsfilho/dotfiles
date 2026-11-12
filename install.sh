#!/usr/bin/env bash
# Symlink tracked dotfiles into $HOME (backs up existing files as *.bak, drops links to deleted files).
# Usage: ./install.sh [all|nvim|alacritty|zsh]...      (default: all; DRY_RUN=1 only prints the commands)
#   all        every tracked dotfile and the git hook
#   nvim       only .config/nvim
#   alacritty  only .config/alacritty (+ the per-OS platform.toml)
#   zsh        only .zshrc and .zshenv (install-zsh.sh also installs oh-my-zsh + plugins)
# install-nvim.sh, install-alacritty.sh and install-zsh.sh are shortcuts for these targets.
# The helpers live in scripts/common.sh.
set -euo pipefail
DOTFILES_DIR=$(cd -P "$(dirname "$0")" && pwd)
# shellcheck disable=SC1091
. "$DOTFILES_DIR/scripts/common.sh"

# Files the full install leaves alone: other installers, docs, hooks and optional configs (niri has install-niri.sh).
SKIP='^((install|update)[a-z-]*\.sh|scripts/.*|openspec/.*|\.agents/.*|README.md|\.githooks/.*|\.config/niri/.*)$'

install_nvim()      { link_tracked .config/nvim; prune_links "$HOME/.config/nvim"; }
install_alacritty() { link_tracked .config/alacritty; link_alacritty_platform; prune_links "$HOME/.config/alacritty"; }
install_zsh()       { link_tracked .zshrc .zshenv; }
install_all() {
  link_tracked -x "$SKIP"
  link_alacritty_platform
  run git -C "$DOTFILES_DIR" config core.hooksPath .githooks   # secret-scanning pre-commit hook
  for d in nvim alacritty shell; do prune_links "$HOME/.config/$d"; done
}

[ $# -gt 0 ] || set -- all
for t in "$@"; do
  case $t in
    all|nvim|alacritty|zsh) ;;
    -h|--help) sed -n '2,9p' "$0"; exit 0 ;;
    *) die "unknown target: $t (use all, nvim, alacritty or zsh)" ;;
  esac
done
for t in "$@"; do "install_$t"; echo "$t linked"; done
