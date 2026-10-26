# os-detection Specification

## Purpose
Defines how the setup scripts decide which supported operating system they are running on, so one command
works unchanged across the user's machines.

## Requirements

### Requirement: Automatic OS detection
The setup scripts SHALL detect the host as one of `fedora`, `ubuntu`, `macos` or `freebsd`. Linux hosts SHALL be
classified from `/etc/os-release` (`ID` and `ID_LIKE`): Fedora and RHEL-like as `fedora`, Debian and Ubuntu-like as `ubuntu`.

#### Scenario: Fedora host
- **WHEN** a setup script runs on a host whose `ID` or `ID_LIKE` contains `fedora`
- **THEN** it SHALL use the Fedora behavior

#### Scenario: Debian derivative
- **WHEN** a setup script runs on a host whose `ID_LIKE` contains `debian` or `ubuntu`
- **THEN** it SHALL use the Ubuntu/Debian behavior

#### Scenario: Unsupported system
- **WHEN** the host is another Linux distribution or another operating system
- **THEN** the script SHALL exit with a non-zero status and a message naming the unsupported system

### Requirement: Manual OS override
The scripts SHALL honor the `DOTFILES_OS` environment variable as the OS name instead of detecting it, so another
OS's steps can be previewed with `DRY_RUN=1`.

#### Scenario: Override on another host
- **WHEN** `DOTFILES_OS=ubuntu DRY_RUN=1 ./update.sh` runs on a Fedora host
- **THEN** it SHALL print the Ubuntu update commands without executing any of them

#### Scenario: Override names an OS with no support
- **WHEN** `DOTFILES_OS` names an OS that has no file under `scripts/os/`
- **THEN** the script SHALL exit non-zero stating that the OS is not supported

### Requirement: OS support is pluggable
Supporting an additional OS SHALL require only adding one file under `scripts/os/` that defines the steps it needs,
plus recognizing it in detection; the entry points SHALL skip any step an OS file does not define.

#### Scenario: OS file omits a step
- **WHEN** the selected OS file does not define a step such as a reboot check
- **THEN** the entry point SHALL continue without error and without that step
