# dotfiles

Shell, sway/waybar/wofi, alacritty, htop, neovim and Claude Code config.

    git clone <repo> ~/dotfiles && ~/dotfiles/install.sh

Install the tools the dotfiles depend on first, with the script for your OS
(`DRY_RUN=1` prints the commands without running them; `--gui` also installs sway,
waybar, wofi, rofi, alacritty and fonts):

    ./install-macos.sh            # Homebrew
    ./install-linux.sh [--gui]    # Fedora, Ubuntu/Debian
    ./install-freebsd.sh [--gui]  # pkg + npm (mason has no FreeBSD binaries)

LSPs, formatters and debug adapters are installed by mason on the first nvim launch
(everywhere except FreeBSD, where the script installs them from pkg/npm).

Secrets live in untracked `~/.secrets` (sourced by `.zshrc`), e.g.:

    export GITHUB_PERSONAL_ACCESS_TOKEN=...

To install only the neovim config:

    git clone <repo> ~/dotfiles && ~/dotfiles/install-nvim.sh
