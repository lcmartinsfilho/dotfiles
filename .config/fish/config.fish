# Interactive-only config. Env/PATH live in conf.d/env.fish, helpers in functions/.
status is-interactive; or return

set -g fish_greeting

# fzf: Ctrl-T files, Ctrl-R history, Alt-C cd
command -q fzf; and fzf --fish | source

# fnm: per-project Node versions (.nvmrc / .node-version)
if command -q fnm
    fnm env --use-on-cd --shell fish | source
    # Same hook as fnm's, plus --install-if-missing: download the version on first visit.
    function _fnm_autoload_hook --on-variable PWD --description 'Change Node version on directory change'
        status --is-command-substitution; and return
        if test -f .node-version -o -f .nvmrc -o -f package.json
            fnm use --install-if-missing --silent-if-unchanged
        end
    end
    _fnm_autoload_hook
end

# ---- Abbreviations (expand as you type) ----
abbr -a v nvim
abbr -a vim nvim
abbr -a l eza
abbr -a ll 'eza -lha'
abbr -a lt 'eza --tree --level=2'
abbr -a ff 'fd | fzf'
abbr -a .. 'cd ..'
abbr -a ... 'cd ../..'
abbr -a dotfiles 'cd ~/dotfiles'
abbr -a fishrc 'nvim ~/dotfiles/.config/fish/config.fish'
abbr -a reload 'source ~/.config/fish/config.fish'
abbr -a upd '~/dotfiles/update.sh'
abbr -a update '~/dotfiles/update.sh'

# Git (oh-my-zsh git plugin equivalents)
abbr -a lg lazygit
abbr -a g git
abbr -a ga 'git add'
abbr -a gaa 'git add --all'
abbr -a gb 'git branch'
abbr -a gc 'git commit --verbose'
abbr -a gcmsg 'git commit --message'
abbr -a gd 'git diff'
abbr -a gf 'git fetch'
abbr -a gfa 'git fetch --all --prune'
abbr -a gl 'git pull'
abbr -a gup 'git pull --rebase'
abbr -a gp 'git push'
abbr -a gpf 'git push --force-with-lease'
abbr -a gst 'git status'
abbr -a gsw 'git switch'
abbr -a gsta 'git stash push'
abbr -a gstp 'git stash pop'
abbr -a ghpr 'gh pr create --fill'
abbr -a ghprs 'gh pr list'
abbr -a ghv 'gh repo view --web'

# tmux
abbr -a ta 'tmux attach -t'
abbr -a tn 'tmux new -s'
abbr -a tl 'tmux ls'

# Rust
abbr -a cb 'cargo build'
abbr -a cr 'cargo run'
abbr -a ct 'cargo nextest run'
abbr -a cc 'cargo clippy --all-targets -- -D warnings'
abbr -a cw 'cargo watch -x check'

# Node
abbr -a pn pnpm
abbr -a y yarn

# Sistema
abbr -a ports 'lsof -iTCP -sTCP:LISTEN -n -P'
abbr -a myip 'curl -s ifconfig.me'
abbr -a paths 'printf "%s\n" $PATH'
