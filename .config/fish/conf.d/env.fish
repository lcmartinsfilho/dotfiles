# Environment for every fish session (equivalent of .zshenv/.profile).
set -gx EDITOR nvim
set -gx VISUAL nvim

# -g: session-global (no fish_variables writes); fish_add_path skips duplicates and missing dirs.
fish_add_path -g $HOME/.cargo/bin $HOME/.local/bin
fish_add_path -ga $HOME/.local/share/JetBrains/Toolbox/scripts

# Default fnm Node on PATH for non-interactive fish too (see .config/shell/fnm-path.sh).
fish_add_path -gm $HOME/.local/share/fnm/aliases/default/bin

# Untracked secrets file: lines like `export NAME=value`.
if test -f ~/.secrets
    while read -l line
        set -l m (string match -rg '^\s*export\s+([A-Za-z_][A-Za-z0-9_]*)=(.*)$' -- $line)
        if test (count $m) -eq 2
            set -gx $m[1] (string trim -c '"\'' -- $m[2])
        end
    end <~/.secrets
end
