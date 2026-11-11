function gclean --description "delete merged branches"
    git branch --merged | grep -vE '^\*|main|master|develop' | xargs -r git branch -d
end
