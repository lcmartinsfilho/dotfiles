# dotfiles

Shell, sway/waybar/wofi, alacritty, tmux, htop, neovim and Claude Code config.

    git clone <repo> ~/dotfiles && ~/dotfiles/install.sh

Install the tools the dotfiles depend on first (Fedora, Ubuntu/Debian, macOS and FreeBSD are
detected automatically; `DRY_RUN=1` prints the commands without running them, `DOTFILES_OS=<os>`
forces an OS; `--gui` also installs sway, waybar, wofi, rofi, alacritty and fonts):

    ./install-deps.sh [--gui]

It also makes zsh your login shell (log out and back in for it to apply).

Update system packages, firmware and toolchains (the `upd` alias runs this):

    ./update.sh

Per-OS steps live in `scripts/os/<os>.sh`, shared helpers and steps in `scripts/common.sh`.
To support another OS, add `scripts/os/<os>.sh` defining the `os_*` hooks it needs
(see `fedora.sh`) and teach `detect_os` in `scripts/common.sh` about it.

LSPs, formatters and debug adapters are installed by mason on the first nvim launch
(everywhere except FreeBSD, where the script installs them from pkg/npm).

Secrets live in untracked `~/.secrets` (sourced by `.zshrc`), e.g.:

    export GITHUB_PERSONAL_ACCESS_TOKEN=...

To install only the neovim config:

    git clone <repo> ~/dotfiles && ~/dotfiles/install-nvim.sh
