# Design

## Context

`install-deps.sh` ends with `log "Done. Next: ./install.sh, then 'chsh -s ...' if zsh isn't your login shell."`; nothing sets the shell. Shared steps live in `scripts/common.sh` (`run` honours `DRY_RUN`, `warn`, `have`). The current login shell is read from `getent passwd "$USER"` (on macOS `dscl`; `$SHELL` is unreliable because it reflects the running session).

## Goals / Non-Goals

**Goals:** after install-deps and a re-login, every login (console, SSH, terminal emulator) starts zsh and loads `.zshrc`.

**Non-Goals:** making bash source `.zshrc`; changing `.zshrc` contents; handling shells other than bash/zsh.

## Decisions

- **Add `ensure_login_shell` to `scripts/common.sh`, called from `install-deps.sh` before the final message.** Alternative: an `exec zsh` fallback in `.bash_profile`; rejected because it hides a wrong login shell and breaks bash-only tools.
- **Use `chsh -s "$(command -v zsh)"`, falling back to `sudo usermod -s` on Linux when `chsh` is missing** (Fedora needs `util-linux-user`, which `chsh` ships in). Add that package to `scripts/os/fedora.sh`.
- **Append zsh to `/etc/shells` with sudo if absent**, since `chsh` rejects unlisted shells.
- **Reword the final hint** to say a re-login is needed, since a new terminal window under the old session keeps the old shell.

## Risks / Trade-offs

- [`chsh` prompts for a password] → acceptable interactively; on failure, warn with the manual command rather than abort.
- [Root cause is different from assumed] → task 3 verifies with a console login; if still broken, capture `zsh -lixc exit` output and open a follow-up.
