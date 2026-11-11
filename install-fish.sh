#!/usr/bin/env bash
# Symlink only the tracked fish (+ Oh My Fish) config into $HOME (backs up existing files as *.bak),
# remove dangling symlinks left behind by deleted files, and bootstrap fisher plugins + Oh My Fish.
# fish itself comes from ./install-deps.sh (or your package manager).
set -euo pipefail
DOTFILES_DIR=$(cd -P "$(dirname "$0")" && pwd)
# shellcheck disable=SC1091
. "$DOTFILES_DIR/scripts/common.sh"

link_tracked .config/fish .config/omf
prune_links "$HOME/.config/fish"
setup_fish_plugins
echo "fish config linked"
