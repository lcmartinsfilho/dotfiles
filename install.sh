#!/usr/bin/env bash
# Symlink every tracked dotfile into $HOME (backs up existing files as *.bak).
set -euo pipefail
cd "$(dirname "$0")"
git ls-files | grep -vE '^(install.sh|README.md)$' | while read -r f; do
  mkdir -p "$HOME/$(dirname "$f")"
  [ -e "$HOME/$f" ] && [ ! -L "$HOME/$f" ] && mv "$HOME/$f" "$HOME/$f.bak"
  ln -sfn "$PWD/$f" "$HOME/$f"
done
