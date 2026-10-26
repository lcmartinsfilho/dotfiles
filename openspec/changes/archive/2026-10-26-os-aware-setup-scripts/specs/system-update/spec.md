# Spec Delta

## Purpose

Defines `update.sh`, the single command that brings system packages, firmware and developer toolchains up to
date on any supported OS.

## ADDED Requirements

### Requirement: Single update entry point
Running `update.sh` (also reachable through the `upd` shell alias, identical on every machine) SHALL update the
system using the package manager of the detected OS, then the developer toolchains, then clean up.

#### Scenario: Run on any supported OS
- **WHEN** the user runs `upd`
- **THEN** the system packages for the detected OS are updated, followed by the toolchain updates and cleanup

### Requirement: Per-OS system updates
The update SHALL use the native tooling of the OS: dnf plus firmware and Flatpak on Fedora; apt plus firmware,
snap and Flatpak on Ubuntu/Debian; Homebrew formulae and casks, the App Store (`mas`, when present) and a
listing of pending macOS system updates on macOS; pkg plus `freebsd-update` on FreeBSD.

#### Scenario: Tool not installed
- **WHEN** an optional tool such as `flatpak`, `snap`, `mas` or `fwupdmgr` is absent
- **THEN** its step SHALL be skipped silently

#### Scenario: Firmware has nothing to apply
- **WHEN** the firmware tool reports that no updates are available
- **THEN** the run SHALL continue and report that there are none

### Requirement: Toolchain updates
The update SHALL refresh, when present: Rust (`rustup`), the latest Node LTS through nvm (reinstalling the
current version's global packages, updating npm, and making the LTS the nvm default), npm global packages,
Claude Code, the CodeGraph CLI, and the Neovim plugins and mason tools.

#### Scenario: nvm manages Node
- **WHEN** nvm is installed
- **THEN** the latest LTS Node is installed, becomes the nvm default, and npm globals are updated under it

#### Scenario: Neovim sync
- **WHEN** `nvim` is available
- **THEN** plugins and mason tools are synced headlessly

### Requirement: Cleanup and notices
After updating, the script SHALL remove orphaned packages and SHALL warn when a reboot is pending. On Fedora it
SHALL also warn when the installed release is within 60 days of end of life or a newer release exists; this check
SHALL never fail the run, including when offline.

#### Scenario: Reboot needed
- **WHEN** the OS reports that a reboot is required after updating
- **THEN** a "reboot required" warning is printed

#### Scenario: Fedora end-of-life lookup fails
- **WHEN** the end-of-life lookup cannot reach the network
- **THEN** the update completes with no error

### Requirement: Single privilege prompt
On OSes that use sudo, the script SHALL request the password once at the start and keep the credential valid for
the duration of the run, and SHALL stop doing so when the script exits.

#### Scenario: Long update
- **WHEN** the update runs longer than the sudo timeout
- **THEN** no second password prompt appears

### Requirement: Dry run and failure behavior
With `DRY_RUN=1` the script SHALL print every command it would run and change nothing, without requiring sudo.
Without it, the script SHALL stop at the first failing step.

#### Scenario: Preview
- **WHEN** `DRY_RUN=1 ./update.sh` runs
- **THEN** commands are printed prefixed with `+` and no package, file or setting is modified
