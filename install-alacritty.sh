#!/usr/bin/env bash
# Symlink only the tracked alacritty config into $HOME (backs up existing files as *.bak).
# Also picks the per-OS platform.toml (font size differs between macOS and Linux).
set -euo pipefail
cd "$(dirname "$0")"

git ls-files .config/alacritty | while read -r f; do
  mkdir -p "$HOME/$(dirname "$f")"
  # Already resolves to the repo file (e.g. ~/.config/alacritty is itself a symlink into the repo): leave it.
  [ "$(cd -P "$(dirname "$HOME/$f")" && pwd)/$(basename "$f")" = "$PWD/$f" ] && continue
  if [ -e "$HOME/$f" ] && [ ! -L "$HOME/$f" ]; then
    bak="$HOME/$f.bak"
    [ -e "$bak" ] && bak="$bak.$(date +%s)"
    mv "$HOME/$f" "$bak"
  fi
  ln -sfn "$PWD/$f" "$HOME/$f"
done

# Per-OS settings: platform.toml (untracked) points at platform-<os>.toml.
case "$(uname -s)" in Darwin) os=macos ;; *) os=linux ;; esac
ln -sfn "$PWD/.config/alacritty/platform-$os.toml" "$HOME/.config/alacritty/platform.toml"

# Drop links that point into this repo but whose target no longer exists
if [ -d "$HOME/.config/alacritty" ]; then
  find "$HOME/.config/alacritty" -type l ! -exec test -e {} \; -lname "$PWD/*" -print -delete
fi
echo "alacritty config linked (platform: $os)"
