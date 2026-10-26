# Proposal

## Why

The dotfiles are used on Fedora, Ubuntu/Debian, macOS and FreeBSD, but system updating lived in a single
untracked `~/upd.sh` (Fedora-only, three commands) and dependency installation was split across three
near-identical `install-<os>.sh` scripts that each repeated the same helpers and shared steps. Adding an OS
or changing a shared step meant editing several files, and the `upd` alias had to be edited per machine.

## What Changes

- Move `~/upd.sh` into the repo as `update.sh`, a single entry point that detects the OS and runs the
  matching update steps; point the `upd` alias in `.zshrc` at it (same alias on every machine).
- Extend the update beyond the original dnf/rustup/flatpak: firmware (`fwupdmgr`), Node LTS via nvm and
  npm globals, `claude update`, `codegraph upgrade`, nvim plugin and mason tool sync, orphan-package
  cleanup, a Fedora end-of-life / new-release notice, a pending-reboot check, and a single sudo prompt.
- Replace `install-linux.sh`, `install-macos.sh` and `install-freebsd.sh` with one `install-deps.sh`
  (`--gui`, `DRY_RUN=1`) that uses the same OS detection.
- Put shared helpers and steps in `scripts/common.sh` and OS-specific behavior in
  `scripts/os/{fedora,ubuntu,macos,freebsd}.sh` (plus `linux.sh`, shared by Fedora and Ubuntu).
- Install the OpenSpec CLI (`@fission-ai/openspec`) on every OS from `install-deps.sh`; `update.sh` keeps it
  current through the npm globals update.
- Make `install.sh` skip `scripts/`, `openspec/` and `.agents/` so they are not symlinked into `$HOME`.
- Update `README.md` for the new entry points.
- **BREAKING**: `install-linux.sh`, `install-macos.sh` and `install-freebsd.sh` no longer exist; use
  `install-deps.sh`.

## Capabilities

### New Capabilities
- `os-detection`: choosing the supported OS (Fedora, Ubuntu/Debian, macOS, FreeBSD) for the setup scripts,
  with a manual override, and how an OS is added.
- `system-update`: what `update.sh` updates and how it reports problems on each OS.
- `dependency-install`: what `install-deps.sh` installs and its safety properties (idempotent, dry-run, GUI flag).
- `dotfile-linking`: which tracked files `install.sh` symlinks into `$HOME` and which it deliberately skips.

### Modified Capabilities

## Impact

- Files: `update.sh`, `install-deps.sh`, `scripts/common.sh`, `scripts/os/*.sh` (new); `install-{linux,macos,freebsd}.sh`
  (removed); `install.sh`, `.zshrc`, `README.md` (edited); `~/upd.sh` (deleted from `$HOME`).
- Dependencies: adds the npm package `@fission-ai/openspec`; Fedora's EOL check uses `curl`, `python3` and
  the network endpoint endoflife.date (best effort, never fatal).
- Behavior change: `nvm alias default 'lts/*'` is set on every update, so the default Node follows the latest LTS.
