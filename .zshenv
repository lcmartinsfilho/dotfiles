. "$HOME/.cargo/env"
[ -f "$HOME/.config/shell/nvm-path.sh" ] && . "$HOME/.config/shell/nvm-path.sh"

export EDITOR=nvim
export VISUAL=nvim

# Non-interactive SSH commands (e.g. `ssh host -- mosh-server new`) get no
# LANG, which leaves the C/POSIX locale and breaks mosh-server. Fall back to
# the system default from /etc/locale.conf.
: "${LANG:=en_US.UTF-8}"
export LANG
