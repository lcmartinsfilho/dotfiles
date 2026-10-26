# Design

## Context

The repo had three `install-<os>.sh` scripts (each with its own copy of `log`/`warn`/`have`/`run`, Rust, oh-my-zsh, nvm
and agent steps) and no tracked update script. See proposal.md for motivation. Constraints: scripts must run on
bare systems with only bash, must work under `set -euo pipefail`, must support `DRY_RUN=1`, and `.zshrc` is shared
across machines so it cannot hold per-OS choices. `install.sh` symlinks every tracked file, so anything tracked
that is not a dotfile must be excluded there.

## Goals / Non-Goals

**Goals:**
- One command each for install and update, identical on all OSes.
- Shared steps defined once; OS differences isolated in one file per OS.
- Output of `install-deps.sh` on Fedora and Ubuntu stays equivalent to the old `install-linux.sh`.

**Non-Goals:**
- Unattended OS release upgrades (only a notice is shown).
- A failure-summary mode that continues past a failed step.
- Arch, Alpine or other distributions (the structure allows adding them later).

## Decisions

- **Hook functions per OS file, orchestration in the entry point.** `update.sh` and `install-deps.sh` own the order
  of steps and call `os_*` hooks through `hook()`, which skips undefined ones. Alternative: one script per OS
  (previous layout), rejected because shared changes needed N edits and drifted. Alternative: a big `case $OS`
  in one file, rejected because each OS's logic grows independently.
- **`linux.sh` shared by `fedora.sh` and `ubuntu.sh`.** Holds the Neovim/fzf/gitleaks/eza/tree-sitter logic and firmware/Flatpak
  updates; the distro file supplies `pm_install` and `PM_HAS_TREE_SITTER`. Avoids `if [ "$PM" = apt ]` branches
  spread across shared code while not duplicating ~60 lines.
- **Detection via `uname` + `/etc/os-release`, with `DOTFILES_OS` override.** The override lets the other three OSes'
  commands be reviewed with `DRY_RUN=1` from one machine, which is the only way they were checked here.
- **Entry point named `install-deps.sh`.** `install.sh` already means "symlink dotfiles"; reusing it would change a
  documented command.
- **nvm runs in a subshell with `set +eu`.** `nvm.sh` breaks under errexit/nounset; a subshell isolates that, and
  `npm update -g` runs inside it so it targets the newly installed Node rather than the one inherited from the caller.
- **`nvm alias default 'lts/*'` on update.** Without it the new LTS is installed but new shells keep the old default.
  Trade-off: it overrides a deliberately pinned default.
- **FreeBSD specifics as variables, not branches.** `OS_NODE=pkg` skips nvm (Node comes from pkg) and
  `RUSTUP_INIT=rustup-init` makes the shared Rust step use the packaged installer. FreeBSD may use `doas`; the
  password keepalive only applies to `sudo`.
- **Privilege handling centralized in `setup_sudo`.** Root → none; FreeBSD prefers `doas`; otherwise `sudo`. In dry run
  it never aborts for missing sudo. macOS defines `os_setup` as a no-op because Homebrew must not run as root.
- **Installer commands wrapped in functions before `run`.** `run omz_installer` instead of `run sh -c "$(curl ...)"`, so
  dry run does not perform the download while expanding the command substitution.
- **Fedora EOL check via endoflife.date, best effort.** Parsed with `python3 -I` (no user-site imports); any failure is
  swallowed. Chosen over hardcoding release dates, which go stale.
- **`set -e` retained.** A failing step aborts the update. A continue-and-summarize mode was offered and not requested.
- **`install.sh` exclusion list extended** to `scripts/`, `openspec/` and `.agents/` (the last two appeared when OpenSpec
  was initialized in the repo) so tooling files are not linked into `$HOME`.

## Risks / Trade-offs

- [macOS, Ubuntu and FreeBSD paths were never executed on those OSes, only dry-run on Fedora] → keep `DOTFILES_OS`
  dry-run available; expect first real runs on those systems to need small fixes.
- [Live update steps (`claude update`, `codegraph upgrade`, nvm install, nvim sync, `fwupdmgr`) were not run during
  development] → they are guarded by `have` and surface their own errors under `set -e`.
- [`nvm alias default` overrides a pinned Node default] → documented in the spec; remove the line if undesired.
- [`npm update -g` in the non-nvm branch uses the default prefix, so FreeBSD's `--prefix ~/.local` tools are not
  covered] → acceptable for now; revisit if FreeBSD updates are needed.
- [Removing `install-<os>.sh` breaks old bookmarks and muscle memory] → listed as BREAKING in the proposal and the
  README documents the replacement.
