# Proposal

## Why

On a real Linux console (Ctrl+Alt+F3) on Fedora, `~/.zshrc` is not loaded the first time a login is opened: no
oh-my-zsh prompt, no aliases, no `fzf`/`nvm`. The dotfiles link `.zshrc` correctly, and a forced `zsh -l -i` with
`TERM=linux` loads it fine, so the file is not the problem. The likeliest cause is that the login shell was still bash
when the session started: `install-deps.sh` only *prints* a `chsh` hint, and a `chsh` takes effect only at the next login,
so a console login after a fresh install runs `.bash_profile`/`.bashrc`, which never source `.zshrc`.

## What Changes

- `install-deps.sh` sets zsh as the login shell for the current user when it is not already (idempotent), instead of only printing a hint.
- It makes sure zsh is listed in `/etc/shells` first, and tells the user a re-login (not just a new window) is needed for it to apply.
- It does nothing under `DRY_RUN=1` beyond printing the commands, and warns (without failing) when `chsh` cannot run.

## Capabilities

### New Capabilities

### Modified Capabilities
- `dependency-install`: adds a requirement that the script makes zsh the login shell.

## Impact

- `install-deps.sh` (final hint) and `scripts/common.sh` (new shared step).
- Assumption: the root cause is the login shell, not an error inside `.zshrc`. If the symptom persists after re-login, the task list includes a check to capture the startup error.
