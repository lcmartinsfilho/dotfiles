# Put the newest nvm-installed node on PATH without loading nvm.sh, so shells and
# apps that never read .zshrc/.bashrc (GUI launchers, scripts) still get the
# userspace node/npm. Appended so it cannot shadow system binaries (a system node, if any, wins here;
# interactive shells still get nvm.sh, which prepends the active version). Sourced from .zshenv and .profile.
_nvm_bin=$(ls -d "${NVM_DIR:-$HOME/.nvm}"/versions/node/*/bin 2>/dev/null | sort -V | tail -n 1)
case ":$PATH:" in
  *":$_nvm_bin:"*) ;;
  *) [ -n "$_nvm_bin" ] && PATH="$PATH:$_nvm_bin" ;;
esac
unset _nvm_bin
export PATH
