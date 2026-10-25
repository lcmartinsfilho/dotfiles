# dotfiles

Shell, sway/waybar/wofi, alacritty, htop, neovim and Claude Code config.

    git clone <repo> ~/dotfiles && ~/dotfiles/install.sh

Secrets live in untracked `~/.secrets` (sourced by `.zshrc`), e.g.:

    export GITHUB_PERSONAL_ACCESS_TOKEN=...

To install only the neovim config:

    git clone <repo> ~/dotfiles && ~/dotfiles/install-nvim.sh
