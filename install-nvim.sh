#!/usr/bin/env bash
# Symlink only the tracked neovim config into $HOME (backs up existing files as *.bak).
# Also removes dangling symlinks left behind by files that were deleted from the repo.
set -euo pipefail
DOTFILES_DIR=$(cd -P "$(dirname "$0")" && pwd)
# shellcheck disable=SC1091
. "$DOTFILES_DIR/scripts/common.sh"

link_tracked .config/nvim
prune_links "$HOME/.config/nvim"
echo "nvim config linked"
