# Ubuntu / Debian and derivatives. Hooks used by update.sh and install-deps.sh.
PM_HAS_TREE_SITTER=0
pm_install() { run $SUDO apt-get install -y "$@"; }
# shellcheck disable=SC1091
. "$DOTFILES_DIR/scripts/os/linux.sh"

# See fedora.sh for what each package is for.
os_install_base() {
  log "Installing base packages (apt)"
  run $SUDO apt-get update
  pm_install ca-certificates git curl wget unzip tar gzip xz-utils build-essential make zsh \
    python3 python3-venv python3-pip ripgrep fd-find pandoc wl-clipboard xclip fontconfig tmux
  if have fdfind && ! have fd; then run ln -sfn "$(command -v fdfind)" "$BIN/fd"; fi   # Debian renames the binary
}

os_install_gui() {
  pm_try sway swaybg swayidle swaylock waybar wofi rofi alacritty \
    fonts-noto-mono fonts-font-awesome breeze-gtk-theme breeze-icon-theme breeze-cursor-theme
  warn "ptyxis (wofi's term=) has no apt package; install it with flatpak or edit .config/wofi/config"
  install_nerd_symbols_font
  install_jetbrains_nerd_font
}

os_update_system() {
  log "apt"
  run $SUDO apt-get update
  run $SUDO apt-get upgrade -y
  update_firmware
  if have snap; then log "snap"; run $SUDO snap refresh; fi
  update_flatpak
}

os_cleanup() { log "cleanup"; run $SUDO apt-get autoremove -y; }

# A newer Ubuntu release is available (best effort; does not upgrade).
os_eol_check() {
  [ "$DRY_RUN" = 1 ] && return 0
  if have do-release-upgrade; then do-release-upgrade -c 2>/dev/null | grep -i 'new release' || true; fi
}

os_reboot_check() { if [ -f /var/run/reboot-required ]; then warn "reboot required"; fi; }
