#!/usr/bin/env bash
# OPTIONAL: clone the private specs repo and symlink each project's openspec/ to it. Safe to re-run.
# Usage: ./install-specs.sh [--adopt]     (DRY_RUN=1 only prints the commands)
# Env:   SPECS_DIR   checkout (default ~/specs)   SPECS_REPO   remote (default git@github.com:lcmartinsfilho/specs.git)
# Only openspec/ directories are linked (see projects.conf in the specs repo). --adopt replaces an existing
# openspec/ with the link only when its contents are identical to the repo's copy.
# Deliberately NOT run by ./install.sh, ./install-deps.sh or ./update.sh.
set -euo pipefail
DOTFILES_DIR=$(cd -P "$(dirname "$0")" && pwd)
# shellcheck disable=SC1091
. "$DOTFILES_DIR/scripts/common.sh"
DIR=${SPECS_DIR:-$HOME/specs}
REPO=${SPECS_REPO:-git@github.com:lcmartinsfilho/specs.git}
case "${1:-}" in "") ;; --adopt) ;; -h|--help) sed -n '2,7p' "$0"; exit 0 ;; *) die "unknown option: $1" ;; esac

if [ ! -d "$DIR" ]; then
  have git || die "git is required to clone $REPO"
  log "Cloning $REPO"
  run git clone "$REPO" "$DIR"
fi
if [ -d "$DIR/.githooks" ] || [ "$DRY_RUN" = 1 ]; then
  run git -C "$DIR" config core.hooksPath .githooks   # secret-scanning pre-commit hook
fi
log "Linking openspec directories"
if [ "$DRY_RUN" = 1 ] && [ ! -x "$DIR/link-openspec.sh" ]; then
  echo "+ $DIR/link-openspec.sh ${1:-}"
else
  DRY_RUN=$DRY_RUN "$DIR/link-openspec.sh" "$@"
fi
