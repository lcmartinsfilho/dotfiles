# dependency-install Specification

## Purpose
Defines `install-deps.sh`, which installs on a fresh machine the tools the dotfiles depend on, on any supported OS.

## Requirements

### Requirement: Single install entry point
`install-deps.sh` SHALL install the tools the dotfiles require using the steps of the detected OS, and SHALL tell the
user to run `install.sh` next to symlink the dotfiles.

#### Scenario: Fresh machine
- **WHEN** the user runs `./install-deps.sh`
- **THEN** the base packages, Rust, oh-my-zsh, Node (nvm, or pkg on FreeBSD), Claude Code, the CodeGraph CLI and the OpenSpec CLI are installed

### Requirement: Idempotent installs
Re-running the script SHALL NOT reinstall or break tools that are already present and sufficiently recent.

#### Scenario: Re-run
- **WHEN** the script runs on a machine where everything is installed
- **THEN** no download or install of already-present components is attempted

#### Scenario: Neovim too old
- **WHEN** the installed Neovim is older than 0.11
- **THEN** a current Neovim is installed from the official release

### Requirement: OpenSpec CLI installation
The script SHALL install the OpenSpec CLI (`@fission-ai/openspec`) on every OS when it is not already present,
using npm (with a `~/.local` prefix on FreeBSD).

#### Scenario: OpenSpec missing
- **WHEN** `openspec` is not on `PATH`
- **THEN** it is installed through npm

#### Scenario: npm unavailable
- **WHEN** npm is not yet on `PATH`
- **THEN** the script warns with the exact manual command instead of failing

### Requirement: Dry run
With `DRY_RUN=1` the script SHALL print the commands it would run, without executing downloads or installs.

#### Scenario: Preview
- **WHEN** `DRY_RUN=1 ./install-deps.sh` runs
- **THEN** only `+`-prefixed command lines are printed and nothing is installed

### Requirement: Optional desktop packages
With `--gui` the script SHALL also install sway, waybar, wofi, rofi, alacritty, fonts and theme packages on Linux and
FreeBSD; without it, it SHALL say that the desktop pieces were skipped. Packages unavailable on the release SHALL
be reported at the end without aborting.

#### Scenario: GUI flag on macOS
- **WHEN** `--gui` is passed on macOS
- **THEN** a warning states there are no desktop packages for macOS and the run continues

#### Scenario: Package missing on this release
- **WHEN** a desktop package does not exist on the host's release
- **THEN** it is listed in a final warning and the remaining packages are still installed

### Requirement: Unknown options rejected
The script SHALL accept only `--gui` and `-h`/`--help`.

#### Scenario: Bad flag
- **WHEN** an unknown option is passed
- **THEN** the script exits non-zero with an "unknown option" message

### Requirement: zsh is the login shell
The script SHALL make zsh the login shell of the current user when it is not already, so that a console or SSH login
reads `~/.zshenv` and `~/.zshrc`. It SHALL ensure zsh is listed in `/etc/shells` before changing the shell, and SHALL
state that the change takes effect at the next login.

#### Scenario: Login shell is bash
- **WHEN** the script runs and the user's login shell is not zsh
- **THEN** the login shell is changed to the installed zsh and a message says to log out and in again

#### Scenario: Already zsh
- **WHEN** the user's login shell is already zsh
- **THEN** no change is attempted

#### Scenario: Dry run or chsh unavailable
- **WHEN** `DRY_RUN=1` is set, or the shell change cannot be performed
- **THEN** the command is only printed (dry run) or a warning with the exact manual `chsh` command is shown, and the script still finishes successfully
