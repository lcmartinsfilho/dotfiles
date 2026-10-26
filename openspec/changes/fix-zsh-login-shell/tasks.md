## 1. Login shell step

- [x] 1.1 Add `ensure_login_shell` to `scripts/common.sh`: read the login shell via `getent`/`dscl`, skip if already zsh, ensure zsh is in `/etc/shells`, run `chsh` (fallback `sudo usermod -s` on Linux), warn with the manual command on failure
- [x] 1.2 Call it from `install-deps.sh` after the OS steps; reword the final "Done" hint to mention logging out and in
- [x] 1.3 Add `util-linux-user` to the Fedora base packages in `scripts/os/fedora.sh`

## 2. Spec and docs

- [x] 2.1 Mention the login-shell step in `README.md` if it documents install-deps behaviour

## 3. Verification

- [x] 3.1 `DRY_RUN=1 ./install-deps.sh` prints the `chsh` command only when the login shell is not zsh
- [x] 3.2 Re-run on this machine (already zsh): no change attempted
- [x] 3.3 Log out, open a Ctrl+Alt+F3 console, confirm the prompt and aliases load; if not, capture `zsh -lixc exit` output
