#!/usr/bin/env bash
# Update system packages, firmware and toolchains for the current OS (Fedora, Ubuntu/Debian, macOS, FreeBSD).
# Usage: ./update.sh      (DRY_RUN=1 only prints the commands; DOTFILES_OS=<os> forces the OS)
# Per-OS steps live in scripts/os/<os>.sh; steps shared by every OS live in scripts/common.sh.
set -euo pipefail

DOTFILES_DIR=$(cd -P "$(dirname "$0")" && pwd)
# shellcheck disable=SC1091
. "$DOTFILES_DIR/scripts/common.sh"

case "${1:-}" in
  "") ;;
  -h|--help) sed -n '2,4p' "$0"; exit 0 ;;
  *) die "unknown option: $1" ;;
esac

detect_os
load_os
log "Updating ($OS)"

hook os_setup
hook os_update_system
update_dev_tools
hook os_cleanup
hook os_eol_check
hook os_reboot_check
