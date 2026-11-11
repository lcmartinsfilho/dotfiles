# Put fnm's default Node on PATH without running `fnm env`, so shells and apps that never
# read .zshrc/.bashrc/config.fish (GUI launchers, scripts) still get the userspace node/npm
# instead of the system one. Sourced from .zshenv and .profile. Interactive shells then
# run `fnm env --use-on-cd` for per-project versions.
for _fnm_dir in "${FNM_DIR:-}" "${XDG_DATA_HOME:-$HOME/.local/share}/fnm" "$HOME/Library/Application Support/fnm"; do
  [ -n "$_fnm_dir" ] && [ -d "$_fnm_dir/aliases/default/bin" ] && break
  _fnm_dir=
done
case ":$PATH:" in
  *":$_fnm_dir/aliases/default/bin:"*) ;;
  *) [ -n "$_fnm_dir" ] && PATH="$_fnm_dir/aliases/default/bin:$PATH" ;;
esac
unset _fnm_dir
export PATH
