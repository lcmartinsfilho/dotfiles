# Put the newest nvm-installed node on PATH without loading nvm.sh, so shells and
# apps that never read .zshrc/.bashrc (GUI launchers, scripts) still get the
# userspace node/npm instead of the system one. Sourced from .zshenv and .profile.
_nvm_bin=$(ls -d "${NVM_DIR:-$HOME/.nvm}"/versions/node/*/bin 2>/dev/null | sort -V | tail -n 1)
case ":$PATH:" in
  *":$_nvm_bin:"*) ;;
  *) [ -n "$_nvm_bin" ] && PATH="$_nvm_bin:$PATH" ;;
esac
unset _nvm_bin
export PATH
