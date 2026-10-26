# Spec Delta

## Purpose

Defines which files of the dotfiles repository `install.sh` links into `$HOME` and which stay in the repository only.

## ADDED Requirements

### Requirement: Repository-only files are not linked
`install.sh` SHALL NOT symlink into `$HOME` the setup scripts (`install*.sh`, `update*.sh`), the `scripts/`
directory, the `openspec/` directory, the `.agents/` directory, `README.md` or `.githooks/`.

#### Scenario: Run install.sh
- **WHEN** `install.sh` links the tracked files
- **THEN** none of `update.sh`, `install-deps.sh`, `scripts/*`, `openspec/*`, `.agents/*`, `README.md` or `.githooks/*` appears in `$HOME`

### Requirement: Tracked dotfiles are linked and existing files preserved
Every other tracked file SHALL be symlinked to the same relative path in `$HOME`; an existing regular file at that
path SHALL be moved to a `.bak` file (timestamped if a backup exists) before linking.

#### Scenario: Existing config file
- **WHEN** a regular file already exists at the target path
- **THEN** it is renamed to `<name>.bak` and the symlink is created
