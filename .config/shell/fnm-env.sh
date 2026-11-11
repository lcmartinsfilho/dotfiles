# fnm for interactive zsh and bash (sourced from .zshrc/.bashrc; fish has its own in config.fish).
# Like `fnm env --use-on-cd`, but the hook also: looks for .node-version/.nvmrc in parent dirs,
# installs the version if missing, and goes back to the default Node after leaving the project.
command -v fnm >/dev/null 2>&1 || return 0

if [ -n "${ZSH_VERSION:-}" ]; then _fnm_shell=zsh; else _fnm_shell=bash; fi
eval "$(fnm env --version-file-strategy=recursive --shell "$_fnm_shell")"

_fnm_autoload_hook() {
  local d=$PWD
  while [ ! -f "$d/.node-version" ] && [ ! -f "$d/.nvmrc" ]; do
    [ "$d" = / ] && break
    d=${d%/*}; [ -n "$d" ] || d=/
  done
  if [ -f "$d/.node-version" ] || [ -f "$d/.nvmrc" ]; then
    _FNM_PROJECT_NODE=1
    fnm use --install-if-missing --silent-if-unchanged
  elif [ -n "${_FNM_PROJECT_NODE:-}" ]; then
    unset _FNM_PROJECT_NODE
    fnm use default --silent-if-unchanged
  fi
}

if [ "$_fnm_shell" = zsh ]; then
  autoload -U add-zsh-hook
  add-zsh-hook -D chpwd _fnm_autoload_hook
  add-zsh-hook chpwd _fnm_autoload_hook
else
  # bash has no chpwd: run the hook from PROMPT_COMMAND when $PWD changed.
  _fnm_bash_hook() { [ "$PWD" = "${_FNM_LAST_PWD:-}" ] && return 0; _FNM_LAST_PWD=$PWD; _fnm_autoload_hook; }
  case ";${PROMPT_COMMAND:-};" in
    *";_fnm_bash_hook;"*) ;;
    *) PROMPT_COMMAND="_fnm_bash_hook${PROMPT_COMMAND:+;$PROMPT_COMMAND}" ;;
  esac
fi
unset _fnm_shell
_fnm_autoload_hook
