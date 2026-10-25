#!/usr/bin/env bash
# Symlink every tracked dotfile into $HOME (backs up existing files as *.bak).
set -euo pipefail
cd "$(dirname "$0")"
git ls-files | grep -vE '^(install.sh|install-nvim.sh|README.md|\.githooks/.*)$' | while read -r f; do
  mkdir -p "$HOME/$(dirname "$f")"
  [ -e "$HOME/$f" ] && [ ! -L "$HOME/$f" ] && mv "$HOME/$f" "$HOME/$f.bak"
  ln -sfn "$PWD/$f" "$HOME/$f"
done

# Per-OS alacritty settings (font size differs between macOS and Linux).
case "$(uname -s)" in Darwin) os=macos ;; *) os=linux ;; esac
ln -sfn "$PWD/.config/alacritty/platform-$os.toml" "$HOME/.config/alacritty/platform.toml"

# Enable the secret-scanning pre-commit hook.
git config core.hooksPath .githooks
