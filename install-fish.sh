#!/usr/bin/env bash
# Symlink only the tracked fish config into $HOME (backs up existing files as *.bak).
# Also removes dangling symlinks left behind by files that were deleted from the repo.
# fish itself comes from ./install-deps.sh (or your package manager).
set -euo pipefail
cd "$(dirname "$0")"
git ls-files .config/fish | while read -r f; do
  mkdir -p "$HOME/$(dirname "$f")"
  # Already resolves to the repo file (e.g. ~/.config/fish is itself a symlink into the repo): leave it.
  [ "$(cd -P "$(dirname "$HOME/$f")" && pwd)/$(basename "$f")" = "$PWD/$f" ] && continue
  if [ -e "$HOME/$f" ] && [ ! -L "$HOME/$f" ]; then
    bak="$HOME/$f.bak"
    [ -e "$bak" ] && bak="$bak.$(date +%s)"
    mv "$HOME/$f" "$bak"
  fi
  ln -sfn "$PWD/$f" "$HOME/$f"
done

# Drop links that point into this repo but whose target no longer exists
if [ -d "$HOME/.config/fish" ]; then
  find "$HOME/.config/fish" -type l ! -exec test -e {} \; -lname "$PWD/*" -print -delete
fi
command -v fish >/dev/null 2>&1 || echo "warning: fish is not installed (run ./install-deps.sh or install it with your package manager)" >&2
echo "fish config linked"
