# Fedora (and RHEL-likes). Hooks used by update.sh and install-deps.sh.
PM_HAS_TREE_SITTER=1
pm_install() { run $SUDO dnf install -y "$@"; }
# shellcheck disable=SC1091
. "$DOTFILES_DIR/scripts/os/linux.sh"

# git/zsh: shell + lazy.nvim; compiler+make: treesitter parsers + telescope-fzf-native;
# ripgrep/fd: telescope; pandoc: pandoc.nvim; python3: mason pypi packages;
# curl/wget/unzip/tar/gzip: mason downloads; wl-clipboard/xclip: clipboard=unnamedplus.
os_install_base() {
  log "Installing base packages (dnf)"
  pm_install git wget unzip tar gzip xz gcc gcc-c++ make zsh util-linux-user python3 python3-pip \
    ripgrep fd-find pandoc wl-clipboard xclip fontconfig
  have curl || pm_install curl   # skip when curl-minimal is already there
}

os_install_gui() {
  pm_try sway swaybg swayidle swaylock waybar wofi rofi-wayland alacritty ptyxis \
    google-noto-sans-mono-fonts fontawesome-fonts-all breeze-gtk breeze-icon-theme breeze-cursor-theme
  have rofi || pm_try rofi   # rofi-wayland was merged into rofi on newer Fedora
  install_nerd_symbols_font
  install_jetbrains_nerd_font
}

os_update_system() {
  log "dnf"
  run $SUDO dnf upgrade -y
  update_firmware
  update_flatpak
}

os_cleanup() { log "cleanup"; run $SUDO dnf autoremove -y; }

# Warn when this Fedora is about to go EOL or a newer release is out (best effort, never fails).
os_eol_check() {
  [ "$DRY_RUN" = 1 ] && return 0
  have curl && have python3 || return 0
  local cur
  cur=$(. /etc/os-release && echo "$VERSION_ID")
  curl -fsS --max-time 10 https://endoflife.date/api/fedora.json 2>/dev/null | python3 -I -c '
import sys, json, datetime
cur = sys.argv[1]
rel = json.load(sys.stdin)
mine = next((r for r in rel if r["cycle"] == cur), None)
new = max(rel, key=lambda r: int(r["cycle"]))["cycle"]
eol = mine["eol"] if mine else None
if isinstance(eol, str):
    days = (datetime.date.fromisoformat(eol) - datetime.date.today()).days
    if days < 60:
        print(f"warn: Fedora {cur} reaches end of life on {eol} ({days} days)", file=sys.stderr)
if int(new) > int(cur):
    print(f"Fedora {new} is available; upgrade with: sudo dnf system-upgrade download --releasever={new}")
' "$cur" || true
}

os_reboot_check() {
  have needs-restarting || return 0
  log "reboot check"
  if [ "$DRY_RUN" = 1 ]; then echo "+ needs-restarting -r"; else needs-restarting -r || warn "reboot required"; fi
}
