## ADDED Requirements

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
