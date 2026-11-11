# Environment for every fish session (equivalent of .zshenv/.profile).
set -gx EDITOR nvim
set -gx VISUAL nvim
set -gx NVM_DIR $HOME/.nvm

# -g: session-global (no fish_variables writes); fish_add_path skips duplicates and missing dirs.
fish_add_path -g $HOME/.cargo/bin $HOME/.local/bin
fish_add_path -ga $HOME/.local/share/JetBrains/Toolbox/scripts

# Newest nvm-installed node on PATH without loading nvm (see .config/shell/nvm-path.sh).
set -l nvm_bins (path filter -d $NVM_DIR/versions/node/*/bin | sort -V)
test (count $nvm_bins) -gt 0; and fish_add_path -gm $nvm_bins[-1]

# Untracked secrets file: lines like `export NAME=value`.
if test -f ~/.secrets
    while read -l line
        set -l m (string match -rg '^\s*export\s+([A-Za-z_][A-Za-z0-9_]*)=(.*)$' -- $line)
        if test (count $m) -eq 2
            set -gx $m[1] (string trim -c '"\'' -- $m[2])
        end
    end <~/.secrets
end
