# Shared by fedora.sh and ubuntu.sh. The distro file must define PM_HAS_TREE_SITTER and
# pm_install() before sourcing this.

NVIM_MIN=0.11          # vim.lsp.config / vim.uv
FZF_MIN=0.48           # `fzf --zsh`
GITLEAKS_VERSION=8.30.1

os_setup() { setup_sudo; }

# Install one by one so a package missing on this release doesn't abort the rest.
pm_try() { local p; for p in "$@"; do pm_install "$p" || MISSING+=("$p"); done; }

os_install_prepare() {
  case $(uname -m) in
    x86_64)        NVIM_ASSET=nvim-linux-x86_64; GL_ARCH=x64 ;;
    aarch64|arm64) NVIM_ASSET=nvim-linux-arm64;  GL_ARCH=arm64 ;;
    *) die "Unsupported architecture: $(uname -m)" ;;
  esac
}

os_install_tools() {
  # Neovim >= 0.11 (distro packages are often too old, e.g. Ubuntu 22.04).
  local v nvim_ok=0 fzf_ok=0
  if have nvim; then
    v=$(nvim --version | sed -n '1s/^NVIM v//p'); v=${v%%-*}
    version_ge "$v" "$NVIM_MIN" && nvim_ok=1
  fi
  if [ "$nvim_ok" = 0 ]; then
    log "Installing Neovim (official release tarball)"
    run bash -c "curl -fsSL https://github.com/neovim/neovim/releases/latest/download/$NVIM_ASSET.tar.gz | tar -xz -C '$HOME/.local/opt'"
    run ln -sfn "$HOME/.local/opt/$NVIM_ASSET/bin/nvim" "$BIN/nvim"
  fi

  # fzf >= 0.48 (.zshrc runs `source <(fzf --zsh)`).
  if have fzf; then version_ge "$(fzf --version | awk '{print $1}')" "$FZF_MIN" && fzf_ok=1; fi
  if [ "$fzf_ok" = 0 ]; then
    log "Installing fzf from upstream"
    [ -d "$HOME/.fzf" ] || run git clone --depth 1 https://github.com/junegunn/fzf.git "$HOME/.fzf"
    run "$HOME/.fzf/install" --bin
    run ln -sfn "$HOME/.fzf/bin/fzf" "$BIN/fzf"
  fi

  # eza, tree-sitter-cli: distro package if any, else build with cargo.
  if ! have eza; then
    pm_install eza || { log "Building eza with cargo"; run cargo install --locked eza; }
  fi
  if ! have tree-sitter; then
    # The prebuilt upstream binaries need a newer glibc than Ubuntu 22.04 has, so build from source.
    { [ "${PM_HAS_TREE_SITTER:-0}" = 1 ] && pm_install tree-sitter-cli; } \
      || { log "Building tree-sitter-cli with cargo (takes a few minutes)"; run cargo install --locked tree-sitter-cli; }
  fi

  # gitleaks (pre-commit hook).
  if ! have gitleaks; then
    log "Installing gitleaks $GITLEAKS_VERSION"
    run bash -c "curl -fsSL https://github.com/gitleaks/gitleaks/releases/download/v$GITLEAKS_VERSION/gitleaks_${GITLEAKS_VERSION}_linux_$GL_ARCH.tar.gz | tar -xz -C '$BIN' gitleaks"
  fi
}

# Claude Code + CodeGraph CLI.
os_install_agents() {
  have claude || run bash -c "curl -fsSL https://claude.ai/install.sh | bash"
  install_codegraph
  install_openspec
}

os_install_notes() {
  echo "Not installed: brave, okular, gwenview (only referenced by mimeapps.list)."
}

update_firmware() {
  have fwupdmgr || return 0
  log "firmware"
  # Exit status 2 means "nothing to do" for refresh/update; any other failure is reported.
  local rc=0
  run $SUDO fwupdmgr refresh --force || true
  run $SUDO fwupdmgr update || rc=$?
  case $rc in
    0) ;;
    2) echo "no firmware updates" ;;
    *) warn "fwupdmgr update failed (exit $rc)" ;;
  esac
}

update_flatpak() { if have flatpak; then log "flatpak"; run $SUDO flatpak update -y; fi; }
