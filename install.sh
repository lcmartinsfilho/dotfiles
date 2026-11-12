#!/usr/bin/env bash
# Symlink tracked dotfiles into $HOME (backs up existing files as *.bak, drops links to deleted files).
# Usage: ./install.sh [all|nvim|alacritty]...      (default: all; DRY_RUN=1 only prints the commands)
#   all        every tracked dotfile and the git hook
#   nvim       only .config/nvim
#   alacritty  only .config/alacritty (+ the per-OS platform.toml)
# install-nvim.sh and install-alacritty.sh are shortcuts for these targets.
# The helpers live in scripts/common.sh.
set -euo pipefail
DOTFILES_DIR=$(cd -P "$(dirname "$0")" && pwd)
# shellcheck disable=SC1091
. "$DOTFILES_DIR/scripts/common.sh"

# Files the full install leaves alone: other installers, docs, hooks and optional configs (niri has install-niri.sh).
SKIP='^((install|update)[a-z-]*\.sh|scripts/.*|openspec/.*|\.agents/.*|README.md|\.githooks/.*|\.config/niri/.*)$'

install_nvim()      { link_tracked .config/nvim; prune_links "$HOME/.config/nvim"; }
install_alacritty() { link_tracked .config/alacritty; link_alacritty_platform; prune_links "$HOME/.config/alacritty"; }
install_all() {
  link_tracked -x "$SKIP"
  link_alacritty_platform
  run git -C "$DOTFILES_DIR" config core.hooksPath .githooks   # secret-scanning pre-commit hook
  for d in nvim alacritty shell; do prune_links "$HOME/.config/$d"; done
}

[ $# -gt 0 ] || set -- all
for t in "$@"; do
  case $t in
    all|nvim|alacritty) ;;
    -h|--help) sed -n '2,8p' "$0"; exit 0 ;;
    *) die "unknown target: $t (use all, nvim or alacritty)" ;;
  esac
done
for t in "$@"; do "install_$t"; echo "$t linked"; done
