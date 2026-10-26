#!/usr/bin/env bash
# Install the tools these dotfiles depend on (macOS, Homebrew). Safe to re-run.
# Usage: ./install-macos.sh        (DRY_RUN=1 ./install-macos.sh only prints the commands)
# Then run ./install.sh to symlink the dotfiles. LSPs/formatters/debuggers are installed
# by mason on the first nvim launch.
set -euo pipefail

DRY_RUN=${DRY_RUN:-0}
NVM_VERSION=v0.40.3

log()  { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33mwarn:\033[0m %s\n' "$*" >&2; }
have() { command -v "$1" >/dev/null 2>&1; }
run()  { if [ "$DRY_RUN" = 1 ]; then printf '+ %s\n' "$*"; else "$@"; fi; }

install_brew() { /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"; }
install_omz() {
  KEEP_ZSHRC=yes RUNZSH=no CHSH=no sh -c \
    "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
}

[ "$(uname -s)" = Darwin ] || { echo "This script is for macOS; use install-linux.sh or install-freebsd.sh." >&2; exit 1; }

# --- Homebrew ---------------------------------------------------------------
if ! have brew; then
  log "Installing Homebrew"
  run install_brew
fi
for b in /opt/homebrew/bin/brew /usr/local/bin/brew; do
  [ -x "$b" ] && { eval "$("$b" shellenv)"; break; }
done
[ "$DRY_RUN" = 1 ] || have brew || { echo "brew not found after install" >&2; exit 1; }

# --- Command-line tools -----------------------------------------------------
# git/zsh: shell + lazy.nvim; neovim >= 0.11 (vim.lsp.config); tree-sitter-cli: nvim-treesitter (main branch);
# eza/fzf: aliases + `fzf --zsh` in .zshrc; ripgrep/fd: telescope; pandoc: pandoc.nvim; gitleaks: pre-commit hook;
# python: mason's pypi packages (ruff, debugpy, basedpyright); wget: mason downloads.
log "Installing formulae"
run brew install git zsh neovim tree-sitter-cli eza fzf ripgrep fd pandoc gitleaks python wget

# --- Apps -------------------------------------------------------------------
# alacritty: terminal; iterm2: provides the cc-status script used by the Claude Code hooks;
# symbols-only nerd font: icons in nvim (mini.icons, blink.cmp).
log "Installing casks"
run brew install --cask alacritty iterm2 font-symbols-only-nerd-font

# Claude Code hooks call ~/.config/iterm2/cc-status (a link into iTerm.app).
cc=/Applications/iTerm.app/Contents/Resources/utilities/cc-status
if [ -e "$cc" ] && [ ! -e "$HOME/.config/iterm2/cc-status" ]; then
  run mkdir -p "$HOME/.config/iterm2"
  run ln -s "$cc" "$HOME/.config/iterm2/cc-status"
fi

# --- Rust (.zshrc/.zshenv/.bashrc source ~/.cargo/env) ------------------------
if [ ! -f "$HOME/.cargo/env" ]; then
  log "Installing Rust via rustup"
  run bash -c "curl -fsSL https://sh.rustup.rs | sh -s -- -y --no-modify-path -c clippy -c rustfmt -c rust-analyzer"
else
  have rustup && run rustup component add clippy rustfmt rust-analyzer
fi

# --- oh-my-zsh (theme "dst", plugin git); KEEP_ZSHRC so the tracked .zshrc survives ---
if [ ! -d "$HOME/.oh-my-zsh" ]; then
  log "Installing oh-my-zsh"
  run install_omz
fi

# --- nvm + Node LTS (needed by mason: vtsls, eslint, prettier, js-debug-adapter) ---
if [ ! -s "$HOME/.nvm/nvm.sh" ]; then
  log "Installing nvm $NVM_VERSION"
  run bash -c "curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/$NVM_VERSION/install.sh | PROFILE=/dev/null bash"
fi
if [ "$DRY_RUN" != 1 ]; then
  export NVM_DIR="$HOME/.nvm"
  # shellcheck disable=SC1091
  set +eu   # nvm.sh isn't safe under errexit/nounset
  . "$NVM_DIR/nvm.sh"
  nvm install --lts
  set -eu
fi

# --- Claude Code + CodeGraph CLI (settings.json hooks call `codegraph prompt-hook`) ---
have claude || run brew install --cask claude-code || warn "claude-code cask failed; see https://claude.ai/install.sh"
if have npm; then
  have codegraph || run npm install -g @colbymchenry/codegraph
else
  warn "npm not on PATH yet; open a new shell and run: npm install -g @colbymchenry/codegraph"
fi

log "Done. Next: ./install.sh, then 'chsh -s \$(which zsh)' if zsh isn't your login shell."
echo "Not installed (not referenced by a tracked file's tooling): brave, okular, gwenview, ptyxis, sway/waybar/wofi (Linux only)."
