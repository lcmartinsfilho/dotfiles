# .bashrc

# Source global definitions
if [ -f /etc/bashrc ]; then
    . /etc/bashrc
fi

# User specific environment
# Appended (not prepended) so user-writable dirs cannot shadow system binaries like sudo/ssh.
case ":$PATH:" in *":$HOME/.local/bin:"*) ;; *) PATH="$PATH:$HOME/.local/bin:$HOME/bin" ;; esac
export PATH

# Uncomment the following line if you don't like systemctl's auto-paging feature:
# export SYSTEMD_PAGER=

# User specific aliases and functions
if [ -d ~/.bashrc.d ]; then
    for rc in ~/.bashrc.d/*; do
        if [ -f "$rc" ]; then
            . "$rc"
        fi
    done
fi
unset rc
. "$HOME/.cargo/env"

# nvm (same as .zshrc)
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && . "$NVM_DIR/bash_completion"
# nvm.sh prepends the active node; move it behind the system dirs (no shadowing of sudo, ssh, ...).
if [ -n "$NVM_BIN" ]; then
  PATH=$(printf %s "$PATH" | tr : "\n" | grep -vxF "$NVM_BIN" | paste -sd:):$NVM_BIN
fi

if [ "$(uname -s)" = Darwin ]; then
  # >>> conda initialize >>>
  # !! Contents within this block are managed by 'conda init' !!
  __conda_setup="$('/usr/bin/conda' 'shell.bash' 'hook' 2> /dev/null)"
  if [ $? -eq 0 ]; then
      eval "$__conda_setup"
  else
      if [ -f "/usr/etc/profile.d/conda.sh" ]; then
          . "/usr/etc/profile.d/conda.sh"
      else
          export PATH="/usr/bin:$PATH"
      fi
  fi
  unset __conda_setup
  # <<< conda initialize <<<
fi

# zoxide (z / zi); keep this last so nothing else overrides its PROMPT_COMMAND hook
command -v zoxide >/dev/null 2>&1 && eval "$(zoxide init bash)"
