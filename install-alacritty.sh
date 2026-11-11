#!/usr/bin/env bash
# Symlink only the tracked alacritty config into $HOME (backs up existing files as *.bak).
# Also picks the per-OS platform.toml (font size differs between macOS and Linux).
set -euo pipefail
DOTFILES_DIR=$(cd -P "$(dirname "$0")" && pwd)
# shellcheck disable=SC1091
. "$DOTFILES_DIR/scripts/common.sh"

link_tracked .config/alacritty
link_alacritty_platform
prune_links "$HOME/.config/alacritty"
echo "alacritty config linked"
