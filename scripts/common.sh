# Shared helpers for update.sh and install-deps.sh. Source it, don't execute it.
# Expects DOTFILES_DIR to be set by the caller.

DRY_RUN=${DRY_RUN:-0}
GUI=${GUI:-0}
INSTALL_CLAUDE=${INSTALL_CLAUDE:-ask}   # ask | yes | no (install-deps.sh --claude / --no-claude)
BIN="$HOME/.local/bin"
MISSING=()
SUDO=""

log()  { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33mwarn:\033[0m %s\n' "$*" >&2; }
die()  { printf 'error: %s\n' "$*" >&2; exit 1; }
have() { command -v "$1" >/dev/null 2>&1; }
run()  { if [ "$DRY_RUN" = 1 ]; then printf '+ %s\n' "$*"; else "$@"; fi; }
version_ge() { [ "$(printf '%s\n%s\n' "$2" "$1" | sort -V | head -n1)" = "$2" ]; }   # $1 >= $2
# Call an OS hook if the OS file defines it.
hook() { if declare -F "$1" >/dev/null; then "$@"; fi; }

# Set OS to fedora | ubuntu | macos | freebsd. Override with DOTFILES_OS=<name> (handy for DRY_RUN tests).
detect_os() {
  if [ -n "${DOTFILES_OS:-}" ]; then OS=$DOTFILES_OS; return; fi
  case "$(uname -s)" in
    Darwin)  OS=macos ;;
    FreeBSD) OS=freebsd ;;
    Linux)
      local ids
      ids=$(. "${OS_RELEASE:-/etc/os-release}"; echo " ${ID:-} ${ID_LIKE:-} ")
      case $ids in
        *" fedora "*|*" rhel "*)   OS=fedora ;;
        *" debian "*|*" ubuntu "*) OS=ubuntu ;;
        *) die "Unsupported Linux distro:$ids(need Fedora or Ubuntu/Debian based)" ;;
      esac ;;
    *) die "Unsupported OS: $(uname -s)" ;;
  esac
}

load_os() {
  [ -f "$DOTFILES_DIR/scripts/os/$OS.sh" ] || die "No support for '$OS' (missing scripts/os/$OS.sh)"
  # shellcheck disable=SC1090
  . "$DOTFILES_DIR/scripts/os/$OS.sh"
}

# Pick the privilege escalation tool and, for sudo, ask for the password once and keep it alive.
setup_sudo() {
  if [ "$(id -u)" = 0 ]; then SUDO=""
  elif have sudo; then SUDO=sudo
  elif have doas; then SUDO=doas
  elif [ "$DRY_RUN" = 1 ]; then SUDO=sudo
  else die "Need root, sudo or doas."; fi

  if [ "$SUDO" = sudo ] && [ "$DRY_RUN" != 1 ]; then
    sudo -v
    while true; do sudo -n true; sleep 50; kill -0 "$$" 2>/dev/null || exit; done 2>/dev/null &
    KEEPALIVE_PID=$!
    trap 'kill "$KEEPALIVE_PID" 2>/dev/null || true' EXIT
  fi
}

# --- Steps shared by every OS ------------------------------------------------

# .zshrc/.zshenv/.bashrc source ~/.cargo/env. RUSTUP_INIT (set by an OS file) is a packaged rustup-init.
install_rust() {
  if [ ! -f "$HOME/.cargo/env" ]; then
    log "Installing Rust via rustup"
    if [ -n "${RUSTUP_INIT:-}" ]; then
      run "$RUSTUP_INIT" -y --no-modify-path -c clippy -c rustfmt -c rust-analyzer
    else
      run bash -c "curl -fsSL https://sh.rustup.rs | sh -s -- -y --no-modify-path -c clippy -c rustfmt -c rust-analyzer"
    fi
  elif have rustup; then
    run rustup component add clippy rustfmt rust-analyzer
  fi
  if [ -f "$HOME/.cargo/env" ]; then
    # shellcheck disable=SC1091
    . "$HOME/.cargo/env"
  fi
}

# Theme "dst", plugin git; KEEP_ZSHRC so the tracked .zshrc survives.
omz_installer() {
  KEEP_ZSHRC=yes RUNZSH=no CHSH=no sh -c \
    "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
}
install_omz() {
  [ -d "$HOME/.oh-my-zsh" ] && return 0
  log "Installing oh-my-zsh"
  run omz_installer
}

# Make zsh the login shell: a console/SSH login only reads .zshrc when it is. Takes effect at the next login.
login_shell() {
  if have getent; then getent passwd "$USER" | cut -d: -f7
  elif have dscl; then dscl . -read "/Users/$USER" UserShell | awk '{print $2}'
  fi
}
ensure_login_shell() {
  local zsh_path
  zsh_path=$(command -v zsh) || { [ "$DRY_RUN" = 1 ] && zsh_path=/usr/bin/zsh || { warn "zsh not found; cannot set it as login shell"; return 0; }; }
  case "$(login_shell)" in */zsh) return 0 ;; esac
  log "Setting zsh as the login shell"
  if [ -f /etc/shells ] && ! grep -qx "$zsh_path" /etc/shells; then
    if [ "$DRY_RUN" = 1 ]; then printf '+ echo %s | %s tee -a /etc/shells\n' "$zsh_path" "${SUDO:-sudo}"
    else echo "$zsh_path" | $SUDO tee -a /etc/shells >/dev/null || warn "could not add $zsh_path to /etc/shells"; fi
  fi
  if have chsh; then run chsh -s "$zsh_path" || warn "chsh failed; run: chsh -s $zsh_path"
  elif have usermod; then run $SUDO usermod -s "$zsh_path" "$USER" || warn "usermod failed; run: sudo usermod -s $zsh_path $USER"
  else warn "no chsh/usermod; set the login shell to $zsh_path manually"; fi
  LOGIN_SHELL_CHANGED=1
}

# fnm + Node LTS (needed by mason: vtsls, eslint, prettier, js-debug-adapter).
# fnm is a single Rust binary: brew on macOS, otherwise built with cargo (install_rust runs first; ~5 min).
install_fnm_node() {
  if ! have fnm; then
    log "Installing fnm"
    if have brew; then run brew install fnm
    else run cargo install --locked fnm; fi
  fi
  [ "$DRY_RUN" = 1 ] && return 0
  fnm install --lts && fnm default lts-latest
}

# settings.json hooks call `codegraph prompt-hook`.
install_codegraph() {
  have codegraph && return 0
  if have npm; then
    run npm install -g @colbymchenry/codegraph
  else
    warn "npm not on PATH yet; open a new shell and run: npm install -g @colbymchenry/codegraph"
  fi
}

# Whether to install Claude Code: never when it is already there; otherwise ask (default no),
# unless --claude / --no-claude decided it. Without a terminal to ask on, skip it.
claude_wanted() {
  have claude && return 1
  case $INSTALL_CLAUDE in yes) return 0 ;; no) return 1 ;; esac
  if [ ! -t 0 ]; then warn "not asking about Claude Code (no terminal); pass --claude to install it"; return 1; fi
  local a
  read -r -p "Install Claude Code? [y/N] " a || return 1
  case $a in [Yy]*) return 0 ;; *) return 1 ;; esac
}

# OpenSpec CLI (spec-driven workflow); `openspec init` in a project sets up its Claude Code commands.
install_openspec() {
  have openspec && return 0
  if have npm; then
    run npm install -g @fission-ai/openspec@latest
  else
    warn "npm not on PATH yet; open a new shell and run: npm install -g @fission-ai/openspec@latest"
  fi
}

install_nerd_font() {
  local archive="$1" label="$2" dir="$HOME/.local/share/fonts/$1"
  [ -d "$dir" ] && return 0
  run mkdir -p "$dir"
  run bash -c "curl -fsSL https://github.com/ryanoasis/nerd-fonts/releases/latest/download/$archive.tar.xz | tar -xJ -C '$dir'" \
    || warn "could not install the $label"
  run fc-cache -f
}

install_nerd_symbols_font() { install_nerd_font NerdFontsSymbolsOnly "Symbols Nerd Font"; }
install_jetbrains_nerd_font() { install_nerd_font JetBrainsMono "JetBrainsMono Nerd Font"; }

# Updates for the toolchains that live outside the system package manager.
update_rust() { if have rustup; then log "rustup"; run rustup update; fi; }

update_node() {
  if have fnm; then
    log "node (fnm) + npm globals"
    if [ "$DRY_RUN" = 1 ]; then
      echo "+ fnm install --lts && fnm default lts-latest"
      echo "+ npm install -g <globals of the previous node>"
      echo "+ npm update -g"
    else
      # Subshell: errexit would abort on fnm's own non-zero exits, and npm must run under the new node.
      ( set +eu; eval "$(fnm env)"
        fnm use default >/dev/null 2>&1
        # fnm has no --reinstall-packages-from: carry the global packages over by name (npm/corepack ship with node).
        pkgs=$(npm ls -g --depth=0 --parseable 2>/dev/null | sed -n 's#.*/lib/node_modules/##p' | grep -vxE 'npm|corepack')
        fnm install --lts && fnm default lts-latest   # new shells follow the latest LTS
        fnm use default >/dev/null
        npm install -g --no-fund --no-audit npm@latest $pkgs
        npm update -g )
    fi
  elif have npm; then
    # pkg-managed npm (FreeBSD) has a root-owned prefix; os_install_agents installs into ~/.local.
    log "npm globals"; run npm update -g --prefix "$HOME/.local"
  fi
}

update_dev_tools() {
  update_rust
  update_node
  if have claude; then log "claude"; run claude update; fi
  if have codegraph; then log "codegraph"; run codegraph upgrade; fi
  if have nvim; then
    log "nvim plugins + mason tools"
    run nvim --headless "+Lazy! sync" "+luafile $DOTFILES_DIR/scripts/nvim-sync.lua" +qa
  fi
}
