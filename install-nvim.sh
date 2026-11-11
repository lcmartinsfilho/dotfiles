#!/usr/bin/env bash
# Shortcut for ./install.sh nvim (see install.sh).
exec "$(dirname "$0")/install.sh" nvim "$@"
