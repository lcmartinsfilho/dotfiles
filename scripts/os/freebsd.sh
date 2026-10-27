# FreeBSD. Hooks used by update.sh and install-deps.sh.
# Mason has no FreeBSD binaries, so LSPs and formatters come from pkg(8) or npm here
# (lsp.lua only asks mason for the npm-based tools on FreeBSD). codelldb has no FreeBSD build,
# so C/C++/Rust debugging through nvim-dap is unavailable.
LTEX_VERSION=18.7.0
RUSTUP_INIT=rustup-init
OS_NODE=pkg   # node/npm come from pkg, not nvm

os_setup() { setup_sudo; }

pkg_try() { local p; for p in "$@"; do run $SUDO pkg install -y "$p" || MISSING+=("$p"); done; }

# bash: the scripts here; git/zsh/gmake: shell, lazy.nvim, telescope-fzf-native (cc is in base);
# neovim >= 0.11; tree-sitter-cli: nvim-treesitter; eza/fzf: .zshrc; ripgrep/fd-find: telescope;
# hs-pandoc: pandoc.nvim; gitleaks: pre-commit hook; node/npm: mason npm tools;
# python3: mason pypi/venv; openjdk21: ltex-ls-plus; wl-clipboard/xclip: clipboard=unnamedplus;
# lua-language-server, stylua, ruff, llvm19 (clangd/clang-format), rust-analyzer: LSPs/formatters mason can't fetch here.
os_install_base() {
  log "Installing packages"
  run $SUDO pkg install -y bash git curl wget unzip gmake zsh tmux neovim tree-sitter-cli eza fzf ripgrep fd-find \
    hs-pandoc gitleaks node npm python3 openjdk21 wl-clipboard xclip \
    lua-language-server stylua ruff py312-debugpy llvm19 rustup-init
}

os_install_tools() {
  # clangd / clang-format ship under /usr/local/llvmNN/bin; expose them without the version suffix.
  local t p
  for t in clangd clang-format clang-tidy; do
    p=$(ls /usr/local/llvm*/bin/"$t" 2>/dev/null | sort -V | tail -n1 || true)
    [ -n "$p" ] && run ln -sfn "$p" "$BIN/$t"
  done

  # ltex-ls-plus: generic tarball (needs Java; lsp.lua points JAVA_HOME at /usr/local/openjdk21).
  if [ ! -x "$BIN/ltex-ls-plus" ]; then
    log "Installing ltex-ls-plus $LTEX_VERSION"
    run bash -c "curl -fsSL https://github.com/ltex-plus/ltex-ls-plus/releases/download/$LTEX_VERSION/ltex-ls-plus-$LTEX_VERSION.tar.gz | tar -xz -C '$HOME/.local/opt'"
    run ln -sfn "$HOME/.local/opt/ltex-ls-plus-$LTEX_VERSION/bin/ltex-ls-plus" "$BIN/ltex-ls-plus"
  fi
  return 0
}

# npm-based tools (user prefix ~/.local, no root).
os_install_agents() {
  log "Installing npm global tools"
  local npm="npm install -g --prefix $HOME/.local"
  have basedpyright-langserver || run $npm basedpyright
  have openspec                || run $npm @fission-ai/openspec@latest
}

os_install_gui() {
  pkg_try sway swaybg swayidle swaylock waybar wofi rofi alacritty ptyxis \
    noto-sans-mono font-awesome plasma6-breeze-gtk kf6-breeze-icons
  install_nerd_symbols_font
  install_jetbrains_nerd_font
}

os_install_notes() {
  echo "Not installed: basedpyright is npm-based and codelldb is unavailable on FreeBSD; brave, okular, gwenview are only referenced by mimeapps.list."
}

os_update_system() {
  log "pkg"
  run $SUDO pkg update
  run $SUDO pkg upgrade -y
  # Packaged base (pkgbase) is upgraded by `pkg upgrade` above; freebsd-update refuses to run there.
  if ! pkg info -e FreeBSD-runtime; then
    log "base system"
    run $SUDO freebsd-update fetch install || true
  fi
}

os_cleanup() {
  log "cleanup"
  run $SUDO pkg autoremove -y
  run $SUDO pkg clean -y
}

# An installed kernel older than the running one means a reboot is pending.
os_reboot_check() {
  [ "$DRY_RUN" = 1 ] && return 0
  [ "$(freebsd-version -k)" != "$(freebsd-version -r)" ] && warn "reboot required"
  return 0
}
