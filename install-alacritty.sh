#!/usr/bin/env bash
# Shortcut for ./install.sh alacritty (see install.sh).
exec "$(dirname "$0")/install.sh" alacritty "$@"
