#!/usr/bin/env bash
# Install the tools these dotfiles depend on (FreeBSD). Safe to re-run.
# Usage: ./install-freebsd.sh [--gui]    (DRY_RUN=1 ./install-freebsd.sh only prints the commands)
#   --gui  also install sway, waybar, wofi, rofi, alacritty, fonts and the Breeze GTK theme
# Then run ./install.sh to symlink the dotfiles.
# Mason has no FreeBSD binaries, so LSPs and formatters come from pkg(8) or npm here
# (lsp.lua only asks mason for the npm-based tools on FreeBSD). codelldb has no FreeBSD build,
# so C/C++/Rust debugging through nvim-dap is unavailable.
set -euo pipefail

DRY_RUN=${DRY_RUN:-0}
GUI=0
for a in "$@"; do
  case $a in
    --gui) GUI=1 ;;
    -h|--help) sed -n '2,8p' "$0"; exit 0 ;;
    *) echo "unknown option: $a" >&2; exit 2 ;;
  esac
done

LTEX_VERSION=18.7.0
BIN="$HOME/.local/bin"
MISSING=()

log()  { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33mwarn:\033[0m %s\n' "$*" >&2; }
have() { command -v "$1" >/dev/null 2>&1; }
run()  { if [ "$DRY_RUN" = 1 ]; then printf '+ %s\n' "$*"; else "$@"; fi; }

install_omz() {
  KEEP_ZSHRC=yes RUNZSH=no CHSH=no sh -c \
    "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
}

[ "$(uname -s)" = FreeBSD ] || { echo "This script is for FreeBSD; use install-macos.sh or install-linux.sh." >&2; exit 1; }

if [ "$(id -u)" = 0 ]; then SUDO=""; elif have doas; then SUDO="doas"; elif have sudo; then SUDO="sudo"; else echo "Need root, doas or sudo." >&2; exit 1; fi
pkg_try() { local p; for p in "$@"; do run $SUDO pkg install -y "$p" || MISSING+=("$p"); done; }

run mkdir -p "$BIN" "$HOME/.local/opt"
case ":$PATH:" in *":$BIN:"*) ;; *) export PATH="$BIN:$PATH" ;; esac

# --- Packages ---------------------------------------------------------------
# bash: install*.sh; git/zsh/gmake: shell, lazy.nvim, telescope-fzf-native (cc is in base);
# neovim >= 0.11; tree-sitter-cli: nvim-treesitter; eza/fzf: .zshrc; ripgrep/fd-find: telescope;
# hs-pandoc: pandoc.nvim; gitleaks: pre-commit hook; node/npm: mason npm tools + claude/codegraph;
# python3: mason pypi/venv; openjdk21: ltex-ls-plus; wl-clipboard/xclip: clipboard=unnamedplus;
# lua-language-server, stylua, ruff, llvm19 (clangd/clang-format), rust-analyzer: LSPs/formatters mason can't fetch here.
log "Installing packages"
run $SUDO pkg install -y bash git curl wget unzip gmake zsh neovim tree-sitter-cli eza fzf ripgrep fd-find \
  hs-pandoc gitleaks node npm python3 openjdk21 wl-clipboard xclip \
  lua-language-server stylua ruff py312-debugpy llvm19 rustup-init

# clangd / clang-format ship under /usr/local/llvmNN/bin; expose them without the version suffix.
for t in clangd clang-format clang-tidy; do
  p=$(ls /usr/local/llvm*/bin/"$t" 2>/dev/null | sort -V | tail -n1 || true)
  [ -n "$p" ] && run ln -sfn "$p" "$BIN/$t"
done

# --- Rust (.zshrc/.zshenv/.bashrc source ~/.cargo/env) ------------------------
if [ ! -f "$HOME/.cargo/env" ]; then
  log "Installing Rust via rustup"
  run rustup-init -y --no-modify-path -c clippy -c rustfmt -c rust-analyzer
elif have rustup; then
  run rustup component add clippy rustfmt rust-analyzer
fi

# --- oh-my-zsh (theme "dst", plugin git); KEEP_ZSHRC so the tracked .zshrc survives ---
if [ ! -d "$HOME/.oh-my-zsh" ]; then
  log "Installing oh-my-zsh"
  run install_omz
fi

# --- npm-based tools (user prefix ~/.local, no root) ----------------------------
log "Installing npm global tools"
NPM="npm install -g --prefix $HOME/.local"
have basedpyright-langserver || run $NPM basedpyright
have codegraph               || run $NPM @colbymchenry/codegraph   # settings.json hooks call `codegraph prompt-hook`
have claude                  || run $NPM @anthropic-ai/claude-code || warn "Claude Code could not be installed via npm on FreeBSD"

# --- ltex-ls-plus: generic tarball (needs Java; lsp.lua points JAVA_HOME at /usr/local/openjdk21) ---
if [ ! -x "$BIN/ltex-ls-plus" ]; then
  log "Installing ltex-ls-plus $LTEX_VERSION"
  run bash -c "curl -fsSL https://github.com/ltex-plus/ltex-ls-plus/releases/download/$LTEX_VERSION/ltex-ls-plus-$LTEX_VERSION.tar.gz | tar -xz -C '$HOME/.local/opt'"
  run ln -sfn "$HOME/.local/opt/ltex-ls-plus-$LTEX_VERSION/bin/ltex-ls-plus" "$BIN/ltex-ls-plus"
fi

# --- Desktop: sway session + terminal + fonts (--gui) -----------------------------
if [ "$GUI" = 1 ]; then
  log "Installing desktop packages"
  pkg_try sway swaybg swayidle swaylock waybar wofi rofi alacritty ptyxis \
    noto-sans-mono font-awesome plasma6-breeze-gtk kf6-breeze-icons
  if [ ! -d "$HOME/.local/share/fonts/NerdFontsSymbolsOnly" ]; then
    run mkdir -p "$HOME/.local/share/fonts/NerdFontsSymbolsOnly"
    run bash -c "curl -fsSL https://github.com/ryanoasis/nerd-fonts/releases/latest/download/NerdFontsSymbolsOnly.tar.xz | tar -xJ -C '$HOME/.local/share/fonts/NerdFontsSymbolsOnly'" \
      || warn "could not install the Symbols Nerd Font"
    run fc-cache -f
  fi
fi

echo
log "Done. Next: ./install.sh, then 'chsh -s /usr/local/bin/zsh' if zsh isn't your login shell."
[ ${#MISSING[@]} -eq 0 ] || warn "packages that failed to install: ${MISSING[*]}"
[ "$GUI" = 1 ] || echo "Desktop pieces (sway/waybar/wofi/alacritty/fonts) were skipped; re-run with --gui to install them."
echo "Not installed: basedpyright is npm-based and codelldb is unavailable on FreeBSD; brave, okular, gwenview are only referenced by mimeapps.list."
