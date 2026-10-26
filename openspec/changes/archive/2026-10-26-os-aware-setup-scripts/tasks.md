# Tasks

## 1. Shared foundation

- [x] 1.1 Create `scripts/common.sh` with `log/warn/die/have/run/version_ge/hook`, `detect_os` (with `DOTFILES_OS`), `load_os` and `setup_sudo`; verify `bash -n` passes and an unsupported `DOTFILES_OS` fails with a clear message
- [x] 1.2 Add shared install steps (`install_rust`, `install_omz`, `install_nvm_node`, `install_codegraph`, `install_openspec`, `install_nerd_symbols_font`) and verify `DRY_RUN=1 ./install-deps.sh` prints them without network access
- [x] 1.3 Add shared update steps (`update_rust`, `update_node`, `update_dev_tools`) and verify `DRY_RUN=1 ./update.sh` lists rustup, nvm/npm, claude, codegraph and nvim sync

## 2. OS hook files

- [x] 2.1 Write `scripts/os/linux.sh`, `fedora.sh` and `ubuntu.sh` (packages, Neovim/fzf/gitleaks/eza/tree-sitter, firmware, Flatpak/snap, cleanup, reboot check, Fedora EOL check); verify Fedora and Ubuntu `DRY_RUN` output of `install-deps.sh --gui` matches the old `install-linux.sh` apart from a renamed function and quoting
- [x] 2.2 Write `scripts/os/macos.sh` (Homebrew bootstrap, formulae, casks, iTerm cc-status link, update and cleanup); verify `DOTFILES_OS=macos DRY_RUN=1` runs both entry points and `--gui` only warns
- [x] 2.3 Write `scripts/os/freebsd.sh` (pkg, llvm links, ltex-ls-plus, npm tools, `OS_NODE=pkg`, `RUSTUP_INIT`, `freebsd-update`, reboot check); verify `DOTFILES_OS=freebsd DRY_RUN=1` runs both entry points
- [x] 2.4 Verify the Fedora end-of-life check runs for real, prints nothing on Fedora 44 and never fails

## 3. Entry points and migration

- [x] 3.1 Add `update.sh` (replacing `~/upd.sh`) and `install-deps.sh` (`--gui`, `-h`); verify `DRY_RUN=1` exits 0 for all four OSes
- [x] 3.2 Delete `~/upd.sh`, `install-linux.sh`, `install-macos.sh` and `install-freebsd.sh`; verify `git status` shows the three installers as deleted
- [x] 3.3 Point `alias upd` in `.zshrc` at `~/dotfiles/update.sh`; verify with `grep -n 'alias upd' .zshrc`

## 4. Linking and docs

- [x] 4.1 Extend the `install.sh` exclusion pattern to `scripts/`, `openspec/` and `.agents/`; verify the filtered `git ls-files` list contains none of them
- [x] 4.2 Install the OpenSpec CLI from `install-deps.sh` on all OSes (`FreeBSD` with `--prefix ~/.local`); verify each OS's dry run contains exactly one `openspec` install line
- [x] 4.3 Update `README.md` for `install-deps.sh`, `update.sh`, `DRY_RUN`, `DOTFILES_OS` and the `scripts/os/` layout; verify the documented commands match the files

## 5. Integration

- [x] 5.1 Commit and push the refactor (`6726766`); verify `git status -sb` shows `main` in sync with `origin/main`
- [x] 5.2 Commit and push the OpenSpec installation, `install.sh` exclusions and this change's artifacts; verify the remote is in sync

## Workflow follow-up

- Archive this change so the four capability specs land in `openspec/specs/`.
- Run the scripts for real on macOS, Ubuntu and FreeBSD machines and fix anything the dry runs could not reveal.
