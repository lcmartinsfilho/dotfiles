#!/usr/bin/env bash
# Symlink tracked dotfiles into $HOME (backs up existing files as *.bak, drops links to deleted files).
# Usage: ./install.sh [all|nvim|alacritty|fish]...      (default: all; DRY_RUN=1 only prints the commands)
#   all        every tracked dotfile, the git hook and the fish plugins
#   nvim       only .config/nvim
#   alacritty  only .config/alacritty (+ the per-OS platform.toml)
#   fish       only .config/fish and .config/omf, then fisher plugins + Oh My Fish
# install-nvim.sh, install-alacritty.sh and install-fish.sh are shortcuts for these targets.
# The helpers live in scripts/common.sh.
set -euo pipefail
DOTFILES_DIR=$(cd -P "$(dirname "$0")" && pwd)
# shellcheck disable=SC1091
. "$DOTFILES_DIR/scripts/common.sh"

# Files the full install leaves alone: other installers, docs, hooks and optional configs (niri has install-niri.sh).
SKIP='^((install|update)[a-z-]*\.sh|scripts/.*|openspec/.*|\.agents/.*|README.md|\.githooks/.*|\.config/niri/.*)$'

install_nvim()      { link_tracked .config/nvim; prune_links "$HOME/.config/nvim"; }
install_alacritty() { link_tracked .config/alacritty; link_alacritty_platform; prune_links "$HOME/.config/alacritty"; }
install_fish()      { link_tracked .config/fish .config/omf; prune_links "$HOME/.config/fish"; prune_links "$HOME/.config/omf"; setup_fish_plugins; }
install_all() {
  link_tracked -x "$SKIP"
  link_alacritty_platform
  run git -C "$DOTFILES_DIR" config core.hooksPath .githooks   # secret-scanning pre-commit hook
  for d in nvim alacritty fish omf shell; do prune_links "$HOME/.config/$d"; done
  setup_fish_plugins
}

[ $# -gt 0 ] || set -- all
for t in "$@"; do
  case $t in
    all|nvim|alacritty|fish) ;;
    -h|--help) sed -n '2,9p' "$0"; exit 0 ;;
    *) die "unknown target: $t (use all, nvim, alacritty or fish)" ;;
  esac
done
for t in "$@"; do "install_$t"; echo "$t linked"; done
