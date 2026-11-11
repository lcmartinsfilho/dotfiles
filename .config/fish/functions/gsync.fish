function gsync --description "fetch all and rebase pull"
    git fetch --all --prune && git pull --rebase --autostash
end
