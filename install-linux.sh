#!/usr/bin/env bash
# Install the tools these dotfiles depend on (Fedora / Ubuntu and derivatives). Safe to re-run.
# Usage: ./install-linux.sh [--gui]      (DRY_RUN=1 ./install-linux.sh only prints the commands)
#   --gui  also install sway, waybar, wofi, rofi, alacritty, fonts and the Breeze GTK theme
# Then run ./install.sh to symlink the dotfiles. LSPs/formatters/debuggers are installed
# by mason on the first nvim launch.
set -euo pipefail

DRY_RUN=${DRY_RUN:-0}
GUI=0
for a in "$@"; do
  case $a in
    --gui) GUI=1 ;;
    -h|--help) sed -n '2,5p' "$0"; exit 0 ;;
    *) echo "unknown option: $a" >&2; exit 2 ;;
  esac
done

NVIM_MIN=0.11          # vim.lsp.config / vim.uv
FZF_MIN=0.48           # `fzf --zsh`
GITLEAKS_VERSION=8.30.1
NVM_VERSION=v0.40.3
BIN="$HOME/.local/bin"
MISSING=()

log()  { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33mwarn:\033[0m %s\n' "$*" >&2; }
have() { command -v "$1" >/dev/null 2>&1; }
run()  { if [ "$DRY_RUN" = 1 ]; then printf '+ %s\n' "$*"; else "$@"; fi; }
version_ge() { [ "$(printf '%s\n%s\n' "$2" "$1" | sort -V | head -n1)" = "$2" ]; }   # $1 >= $2

install_omz() {
  KEEP_ZSHRC=yes RUNZSH=no CHSH=no sh -c \
    "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
}

[ "$(uname -s)" = Linux ] || { echo "This script is for Linux; use install-macos.sh or install-freebsd.sh." >&2; exit 1; }

# --- Distro / privileges ----------------------------------------------------
# shellcheck disable=SC1091
. "${OS_RELEASE:-/etc/os-release}"
case " ${ID:-} ${ID_LIKE:-} " in
  *" fedora "*|*" rhel "*)  PM=dnf ;;
  *" debian "*|*" ubuntu "*) PM=apt ;;
  *) echo "Unsupported distro: ${PRETTY_NAME:-unknown} (need Fedora or Ubuntu/Debian based)" >&2; exit 1 ;;
esac
case $(uname -m) in
  x86_64)        NVIM_ASSET=nvim-linux-x86_64; GL_ARCH=x64 ;;
  aarch64|arm64) NVIM_ASSET=nvim-linux-arm64;  GL_ARCH=arm64 ;;
  *) echo "Unsupported architecture: $(uname -m)" >&2; exit 1 ;;
esac
if [ "$(id -u)" = 0 ]; then SUDO=""; elif have sudo; then SUDO="sudo"; else echo "Need root or sudo." >&2; exit 1; fi

pm_install() {
  case $PM in
    apt) run $SUDO apt-get install -y "$@" ;;
    dnf) run $SUDO dnf install -y "$@" ;;
  esac
}
# Install one by one so a package missing on this release doesn't abort the rest.
pm_try() { local p; for p in "$@"; do pm_install "$p" || MISSING+=("$p"); done; }

run mkdir -p "$BIN" "$HOME/.local/opt"
case ":$PATH:" in *":$BIN:"*) ;; *) export PATH="$BIN:$PATH" ;; esac

# --- Base packages ----------------------------------------------------------
# git/zsh: shell + lazy.nvim; compiler+make: treesitter parsers + telescope-fzf-native;
# ripgrep/fd: telescope; pandoc: pandoc.nvim; python3(+venv): mason pypi packages;
# curl/wget/unzip/tar/gzip: mason downloads; wl-clipboard/xclip: clipboard=unnamedplus.
log "Installing base packages ($PM)"
if [ "$PM" = apt ]; then
  run $SUDO apt-get update
  pm_install ca-certificates git curl wget unzip tar gzip xz-utils build-essential make zsh \
    python3 python3-venv python3-pip ripgrep fd-find pandoc wl-clipboard xclip fontconfig
  have fdfind && ! have fd && run ln -sfn "$(command -v fdfind)" "$BIN/fd"   # Debian renames the binary
else
  pm_install git wget unzip tar gzip xz gcc gcc-c++ make zsh python3 python3-pip \
    ripgrep fd-find pandoc wl-clipboard xclip fontconfig
  have curl || pm_install curl   # skip when curl-minimal is already there
fi

# --- Rust (.zshrc/.zshenv/.bashrc source ~/.cargo/env) ------------------------
if [ ! -f "$HOME/.cargo/env" ]; then
  log "Installing Rust via rustup"
  run bash -c "curl -fsSL https://sh.rustup.rs | sh -s -- -y --no-modify-path -c clippy -c rustfmt -c rust-analyzer"
elif have rustup; then
  run rustup component add clippy rustfmt rust-analyzer
fi
# shellcheck disable=SC1091
[ -f "$HOME/.cargo/env" ] && . "$HOME/.cargo/env"

# --- Neovim >= 0.11 (distro packages are often too old, e.g. Ubuntu 22.04) -----
nvim_ok=0
if have nvim; then
  v=$(nvim --version | sed -n '1s/^NVIM v//p'); v=${v%%-*}
  version_ge "$v" "$NVIM_MIN" && nvim_ok=1
fi
if [ "$nvim_ok" = 0 ]; then
  log "Installing Neovim (official release tarball)"
  run bash -c "curl -fsSL https://github.com/neovim/neovim/releases/latest/download/$NVIM_ASSET.tar.gz | tar -xz -C '$HOME/.local/opt'"
  run ln -sfn "$HOME/.local/opt/$NVIM_ASSET/bin/nvim" "$BIN/nvim"
fi

# --- fzf >= 0.48 (.zshrc runs `source <(fzf --zsh)`) --------------------------
fzf_ok=0
if have fzf; then version_ge "$(fzf --version | awk '{print $1}')" "$FZF_MIN" && fzf_ok=1; fi
if [ "$fzf_ok" = 0 ]; then
  log "Installing fzf from upstream"
  [ -d "$HOME/.fzf" ] || run git clone --depth 1 https://github.com/junegunn/fzf.git "$HOME/.fzf"
  run "$HOME/.fzf/install" --bin
  run ln -sfn "$HOME/.fzf/bin/fzf" "$BIN/fzf"
fi

# --- eza, tree-sitter-cli: distro package if any, else build with cargo ---------
if ! have eza; then
  pm_install eza || { log "Building eza with cargo"; run cargo install --locked eza; }
fi
if ! have tree-sitter; then
  # The prebuilt upstream binaries need a newer glibc than Ubuntu 22.04 has, so build from source.
  { [ "$PM" = dnf ] && pm_install tree-sitter-cli; } || { log "Building tree-sitter-cli with cargo (takes a few minutes)"; run cargo install --locked tree-sitter-cli; }
fi

# --- gitleaks (pre-commit hook) ----------------------------------------------
if ! have gitleaks; then
  log "Installing gitleaks $GITLEAKS_VERSION"
  run bash -c "curl -fsSL https://github.com/gitleaks/gitleaks/releases/download/v$GITLEAKS_VERSION/gitleaks_${GITLEAKS_VERSION}_linux_$GL_ARCH.tar.gz | tar -xz -C '$BIN' gitleaks"
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
have claude || run bash -c "curl -fsSL https://claude.ai/install.sh | bash"
if have npm; then
  have codegraph || run npm install -g @colbymchenry/codegraph
else
  warn "npm not on PATH yet; open a new shell and run: npm install -g @colbymchenry/codegraph"
fi

# --- Desktop: sway session + terminal + fonts (--gui) -----------------------------
if [ "$GUI" = 1 ]; then
  log "Installing desktop packages"
  if [ "$PM" = apt ]; then
    pm_try sway swaybg swayidle swaylock waybar wofi rofi alacritty \
      fonts-noto-mono fonts-font-awesome breeze-gtk-theme breeze-icon-theme breeze-cursor-theme
    warn "ptyxis (wofi's term=) has no apt package; install it with flatpak or edit .config/wofi/config"
  else
    pm_try sway swaybg swayidle swaylock waybar wofi rofi-wayland alacritty ptyxis \
      google-noto-sans-mono-fonts fontawesome-fonts-all breeze-gtk breeze-icon-theme breeze-cursor-theme
    have rofi || pm_try rofi   # rofi-wayland was merged into rofi on newer Fedora
  fi
  if [ ! -d "$HOME/.local/share/fonts/NerdFontsSymbolsOnly" ]; then
    run mkdir -p "$HOME/.local/share/fonts/NerdFontsSymbolsOnly"
    run bash -c "curl -fsSL https://github.com/ryanoasis/nerd-fonts/releases/latest/download/NerdFontsSymbolsOnly.tar.xz | tar -xJ -C '$HOME/.local/share/fonts/NerdFontsSymbolsOnly'" \
      || warn "could not install the Symbols Nerd Font"
    run fc-cache -f
  fi
fi

echo
log "Done. Next: ./install.sh, then 'chsh -s \$(command -v zsh)' if zsh isn't your login shell."
[ ${#MISSING[@]} -eq 0 ] || warn "packages not available on this release: ${MISSING[*]}"
[ "$GUI" = 1 ] || echo "Desktop pieces (sway/waybar/wofi/alacritty/fonts) were skipped; re-run with --gui to install them."
echo "Not installed: brave, okular, gwenview (only referenced by mimeapps.list)."
