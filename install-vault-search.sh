#!/usr/bin/env bash
# OPTIONAL: set up vault-search (local semantic search over an Obsidian vault) on this machine. Safe to re-run.
# Usage: ./install-vault-search.sh [--no-index]     (DRY_RUN=1 only prints the commands)
# Env:   VAULT_SEARCH_DIR   project checkout (default ~/projects/vault-search; cloned from VAULT_SEARCH_REPO if missing)
#        VAULT_SEARCH_REPO  git remote of the project (default git@github.com:lcmartinsfilho/vault-search.git)
#        VAULT_PATH         Obsidian vault (asked for if the config doesn't exist yet)
# Does: uv sync, Ollama (installer asks first) as a systemd *user* service, nomic-embed-text, config,
# index timer, MCP registration in Claude Code and OpenCode (only if installed), agent-instruction snippet.
# Deliberately NOT run by ./install.sh, ./install-deps.sh or ./update.sh, and nothing here is symlinked
# into $HOME. Never touches the vault. Templates live in scripts/vault-search/.
set -euo pipefail

DOTFILES_DIR=$(cd -P "$(dirname "$0")" && pwd)
# shellcheck disable=SC1091
. "$DOTFILES_DIR/scripts/common.sh"
T="$DOTFILES_DIR/scripts/vault-search"
PROJECT=${VAULT_SEARCH_DIR:-$HOME/projects/vault-search}
REPO=${VAULT_SEARCH_REPO:-git@github.com:lcmartinsfilho/vault-search.git}
UNITS="$HOME/.config/systemd/user"
CONF="$HOME/.config/vault-search/config.toml"
INDEX=1
case "${1:-}" in
  "") ;;
  --no-index) INDEX=0 ;;
  -h|--help) sed -n '2,9p' "$0"; exit 0 ;;
  *) die "unknown option: $1" ;;
esac

confirm() { [ "$DRY_RUN" = 1 ] && return 0; read -r -p "$1 [y/N] " a; [ "$a" = y ]; }

if [ ! -d "$PROJECT" ]; then
  have git || die "git is required to clone $REPO"
  log "Cloning $REPO"
  run git clone "$REPO" "$PROJECT"
fi
have uv || die "uv is required (see install-deps.sh)"
BIN="$PROJECT/.venv/bin/vault-search"

log "Python environment"
run uv sync --project "$PROJECT"

log "Ollama"
if ! have ollama; then
  confirm "Ollama is missing. Run the official installer (curl | sh, uses sudo)?" \
    && run sh -c 'curl -fsSL https://ollama.com/install.sh | sh' || die "Ollama is required"
fi
if systemctl is-enabled ollama >/dev/null 2>&1; then
  warn "system ollama.service is enabled; if it fails (e.g. missing /var/lib/ollama) disable it: sudo systemctl disable --now ollama"
elif ! curl -sf -m 3 localhost:11434/api/version >/dev/null 2>&1; then
  run mkdir -p "$UNITS"
  run install -m 644 "$T/ollama.service" "$UNITS/ollama.service"
  run systemctl --user daemon-reload
  run systemctl --user enable --now ollama.service
  have loginctl && warn "to start Ollama at boot without logging in: sudo loginctl enable-linger $USER"
fi
if [ "$DRY_RUN" != 1 ]; then
  for _ in $(seq 15); do curl -sf -m 2 localhost:11434/api/version >/dev/null 2>&1 && break; sleep 1; done
  curl -sf -m 2 localhost:11434/api/version >/dev/null 2>&1 || die "Ollama is not answering on :11434"
fi
ollama list 2>/dev/null | grep -q '^nomic-embed-text' || run ollama pull nomic-embed-text

log "Config"
if [ ! -f "$CONF" ]; then
  VP=${VAULT_PATH:-}
  [ -n "$VP" ] || { [ "$DRY_RUN" = 1 ] && VP='<vault>' || read -r -p "Path to your Obsidian vault: " VP; }
  [ -d "${VP/#\~/$HOME}" ] || [ "$DRY_RUN" = 1 ] || die "not a directory: $VP"
  run mkdir -p "$(dirname "$CONF")"
  if [ "$DRY_RUN" = 1 ]; then echo "+ write $CONF (vault_path=$VP)"; else
    (cd "$PROJECT" && uv run python -c "
import sys
from vault_search.config import DEFAULT_TOML, CONFIG_PATH
CONFIG_PATH.write_text(DEFAULT_TOML.format(vault_path=sys.argv[1]))" "$VP"); fi
else
  echo "$CONF exists, leaving it alone"
fi

log "Index timer (systemd user)"
run mkdir -p "$UNITS"
run install -m 644 "$T/vault-search-index.service" "$T/vault-search-index.timer" "$UNITS/"
run systemctl --user daemon-reload
run systemctl --user enable --now vault-search-index.timer

if [ "$INDEX" = 1 ]; then
  log "Initial index (a few minutes for a large vault)"
  run "$BIN" index
fi

log "MCP registration"
if have claude; then
  claude mcp list 2>/dev/null | grep -q '^vault-search' \
    || run claude mcp add vault-search --scope user -- "$BIN" serve
else
  warn "claude not installed, skipping Claude Code"
fi
OC="$HOME/.config/opencode/opencode.jsonc"
if have opencode && [ -f "$OC" ]; then
  if grep -q '"vault-search"' "$OC"; then echo "opencode: already registered"
  elif [ "$DRY_RUN" = 1 ]; then echo "+ add vault-search to $OC"
  else
    python3 - "$OC" "$BIN" <<'PY' || warn "could not edit $OC; add a local mcp entry running: $BIN serve"
import re, sys, json
path, exe = sys.argv[1:3]
s = open(path).read()
entry = '"vault-search": {"type": "local", "command": [%s, "serve"], "enabled": true},' % json.dumps(exe)
new, n = re.subn(r'("mcp"\s*:\s*\{)', lambda m: m.group(1) + "\n    " + entry, s, count=1)
if n != 1:
    sys.exit(1)
open(path, "w").write(new)
PY
  fi
  AG="$HOME/.config/opencode/AGENTS.md"
  if ! grep -q VAULT_SEARCH_START "$AG" 2>/dev/null; then
    if [ "$DRY_RUN" = 1 ]; then echo "+ append snippet to $AG"; else { echo; cat "$T/AGENTS.snippet.md"; } >> "$AG"; fi
  fi
else
  warn "opencode not installed (or no $OC), skipping"
fi

log "Done. For Claude Code, add this to your vault's CLAUDE.md yourself (never written for you):"
echo "  When answering questions about my notes, call \`search_notes\` first. Open the top hits with \`get_note\` and follow [[wikilinks]] when they're relevant. Cite note paths in answers."
