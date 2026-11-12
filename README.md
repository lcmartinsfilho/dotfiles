# dotfiles

Shell, sway/waybar/wofi, alacritty, tmux, htop, neovim (LazyVim) and Claude Code config.

    git clone <repo> ~/dotfiles && ~/dotfiles/install.sh

Install the tools the dotfiles depend on first (Fedora, Ubuntu/Debian, macOS and FreeBSD are
detected automatically; `DRY_RUN=1` prints the commands without running them, `DOTFILES_OS=<os>`
forces an OS; `--gui` also installs sway, waybar, wofi, rofi, alacritty and fonts):

    ./install-deps.sh [--gui]

It also installs the oh-my-zsh plugins zsh-autosuggestions and zsh-syntax-highlighting (fish-like suggestions and highlighting) and makes zsh your login shell (log out and back in for it to apply).

[Niri](https://github.com/YaLTeR/niri) is optional and kept separate (its config lives in `.config/niri/`,
which `install.sh` skips). Install it, its dependencies (waybar, wofi, mako, polkit agent, ...) and
link its config with:

    ./install-niri.sh [--deps-only|--links-only]      # Fedora only for now

Niri starts its own waybar (`.config/niri/waybar.jsonc`) and mako, so the sway setup is unaffected.

Update system packages, firmware and toolchains (the `upd` / `update` aliases run this):

    ./update.sh

Per-OS steps live in `scripts/os/<os>.sh`, shared helpers and steps in `scripts/common.sh`.
To support another OS, add `scripts/os/<os>.sh` defining the `os_*` hooks it needs
(see `fedora.sh`) and teach `detect_os` in `scripts/common.sh` about it.

Neovim runs on [LazyVim](https://www.lazyvim.org) (needs Neovim >= 0.11.2): `.config/nvim` enables a few
LazyVim extras (`lua/config/lazy.lua`) and keeps personal overrides in `lua/plugins/user.lua`.
LSPs, formatters and debug adapters are installed by mason on the first nvim launch
(everywhere except FreeBSD, where the script installs them from pkg/npm and `user.lua` marks
those servers `mason = false`). `update.sh` syncs plugins and mason packages via `scripts/nvim-sync.lua`.

Secrets live in untracked `~/.secrets` (sourced by `.zshrc`), e.g.:

    export GITHUB_PERSONAL_ACCESS_TOKEN=...

To install only the neovim config:

    git clone <repo> ~/dotfiles && ~/dotfiles/install.sh nvim
