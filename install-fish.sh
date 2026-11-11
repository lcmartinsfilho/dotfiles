#!/usr/bin/env bash
# Symlink only the tracked fish (+ Oh My Fish) config into $HOME (backs up existing files as *.bak).
# Also removes dangling symlinks left behind by files that were deleted from the repo.
# fish itself comes from ./install-deps.sh (or your package manager).
set -euo pipefail
cd "$(dirname "$0")"
git ls-files .config/fish .config/omf | while read -r f; do
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
# Plugins: fisher + everything listed in .config/fish/fish_plugins (installed only when fisher is missing)
if command -v fish >/dev/null 2>&1 && ! fish -c 'functions -q fisher' 2>/dev/null; then
  fish -c 'curl -sL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish | source && fisher update' \
    || echo "warning: fisher bootstrap failed (needs curl + network); run: fisher update" >&2
fi
# Oh My Fish (prompt theme): installed once; theme/bundle come from .config/omf (linked above)
if command -v fish >/dev/null 2>&1 && command -v git >/dev/null 2>&1 && [ ! -f "${XDG_DATA_HOME:-$HOME/.local/share}/omf/init.fish" ]; then
  omf_src="$(mktemp -d)"
  if git clone --depth 1 https://github.com/oh-my-fish/oh-my-fish "$omf_src" \
    && fish "$omf_src/bin/install" --offline --noninteractive --yes; then
    fish -c 'omf install' || echo "warning: 'omf install' failed; run it manually" >&2
  else
    echo "warning: Oh My Fish install failed" >&2
  fi
  rm -rf "$omf_src"
fi
command -v fish >/dev/null 2>&1 || echo "warning: fish is not installed (run ./install-deps.sh or install it with your package manager)" >&2
echo "fish config linked"
