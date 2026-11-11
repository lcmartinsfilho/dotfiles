# macOS (Homebrew). Hooks used by update.sh and install-deps.sh.

os_setup() { :; }   # brew needs no sudo

brew_installer() { /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"; }

os_install_prepare() {
  if ! have brew; then
    log "Installing Homebrew"
    run brew_installer
  fi
  local b
  for b in /opt/homebrew/bin/brew /usr/local/bin/brew; do
    [ -x "$b" ] && { eval "$("$b" shellenv)"; break; }
  done
  [ "$DRY_RUN" = 1 ] || have brew || die "brew not found after install"
}

# cask_try name[:App] ...  install each cask unless /Applications/App.app already exists (or brew has it).
cask_try() {
  local spec c app
  for spec in "$@"; do
    c=${spec%%:*}; app=
    [ "$c" != "$spec" ] && app=${spec#*:}
    if [ -n "$app" ] && [ -e "/Applications/$app.app" ]; then log "$c: /Applications/$app.app already present, skipping"; continue; fi
    if [ "$DRY_RUN" != 1 ] && brew list --cask "$c" >/dev/null 2>&1; then continue; fi
    run brew install --cask "$c" || MISSING+=("$c")
  done
}

# git/zsh/fish: shells + lazy.nvim; neovim >= 0.11.2 (LazyVim); tree-sitter-cli: nvim-treesitter (main branch);
# eza/fzf/zoxide: aliases + `fzf --zsh` in .zshrc; ripgrep/fd: snacks picker (LazyVim); pandoc: pandoc.nvim; gitleaks: pre-commit hook;
# python: mason's pypi packages (ruff, debugpy, basedpyright); wget: mason downloads.
os_install_base() {
  log "Installing formulae"
  run brew install git zsh fish neovim tmux tree-sitter-cli eza fzf zoxide ripgrep fd lazygit pandoc gitleaks python wget

  # alacritty: terminal; iterm2: provides the cc-status script used by the Claude Code hooks;
  # nerd fonts: symbols-only gives icons in nvim (mini.icons, blink.cmp); jetbrains is alacritty's font.
  log "Installing casks"
  # One at a time: a cask that is disabled upstream (alacritty) or whose app was installed outside brew
  # (iTerm.app) must not abort the rest; failures are listed at the end.
  cask_try alacritty:Alacritty iterm2:iTerm font-symbols-only-nerd-font font-jetbrains-mono-nerd-font

  # Claude Code hooks call ~/.config/iterm2/cc-status (a link into iTerm.app).
  local cc=/Applications/iTerm.app/Contents/Resources/utilities/cc-status
  if [ -e "$cc" ] && [ ! -e "$HOME/.config/iterm2/cc-status" ]; then
    run mkdir -p "$HOME/.config/iterm2"
    run ln -s "$cc" "$HOME/.config/iterm2/cc-status"
  fi
}

os_install_agents() {
  if claude_wanted; then run brew install --cask claude-code || warn "claude-code cask failed; see https://claude.ai/install.sh"; fi
  install_codegraph
  install_openspec
}

os_install_notes() {
  echo "Not installed (not referenced by a tracked file's tooling): brave, okular, gwenview, ptyxis, sway/waybar/wofi (Linux only)."
}

os_update_system() {
  if have brew; then
    log "homebrew"
    run brew update
    run brew upgrade
    run brew upgrade --cask --greedy
  fi
  if have mas; then log "app store"; run mas upgrade; fi
  log "macOS system updates (list only; install with: sudo softwareupdate --install --all)"
  run softwareupdate --list
}

os_cleanup() {
  have brew || return 0
  log "cleanup"
  run brew autoremove
  run brew cleanup
}
