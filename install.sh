#!/usr/bin/env bash
# Symlink every tracked dotfile into $HOME (backs up existing files as *.bak).
# The partial installers (install-nvim.sh, install-alacritty.sh, install-fish.sh) do the same for one
# tool; all of them share the helpers in scripts/common.sh. DRY_RUN=1 only prints the commands.
set -euo pipefail
DOTFILES_DIR=$(cd -P "$(dirname "$0")" && pwd)
# shellcheck disable=SC1091
. "$DOTFILES_DIR/scripts/common.sh"

link_tracked -x '^((install|update)[a-z-]*\.sh|scripts/.*|openspec/.*|\.agents/.*|README.md|\.githooks/.*|\.config/niri/.*)$'
link_alacritty_platform

# Enable the secret-scanning pre-commit hook.
run git -C "$DOTFILES_DIR" config core.hooksPath .githooks

# Drop links that point into this repo but whose target was deleted (removed plugin specs, functions, ...).
for d in nvim alacritty fish omf shell; do prune_links "$HOME/.config/$d"; done

# fisher plugins + Oh My Fish (same step as install-fish.sh; no-op once installed).
setup_fish_plugins
