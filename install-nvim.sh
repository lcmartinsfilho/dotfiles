#!/usr/bin/env bash
# Symlink only the tracked neovim config into $HOME (backs up existing files as *.bak).
# Also removes dangling symlinks left behind by files that were deleted from the repo.
set -euo pipefail
cd "$(dirname "$0")"
git ls-files .config/nvim | while read -r f; do
  mkdir -p "$HOME/$(dirname "$f")"
  [ "$(cd -P "$(dirname "$HOME/$f")" && pwd)/$(basename "$f")" = "$PWD/$f" ] && continue
  if [ -e "$HOME/$f" ] && [ ! -L "$HOME/$f" ]; then
    bak="$HOME/$f.bak"
    [ -e "$bak" ] && bak="$bak.$(date +%s)"
    mv "$HOME/$f" "$bak"
  fi
  ln -sfn "$PWD/$f" "$HOME/$f"
done

# Drop links that point into this repo but whose target no longer exists
if [ -d "$HOME/.config/nvim" ]; then
  find "$HOME/.config/nvim" -type l ! -exec test -e {} \; -lname "$PWD/*" -print -delete
fi
