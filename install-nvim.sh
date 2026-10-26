#!/usr/bin/env bash
# Symlink only the tracked neovim config into $HOME (backs up existing files as *.bak).
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
