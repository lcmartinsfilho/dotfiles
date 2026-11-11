function nl --description "pm run lint"
    set -l pm (_pm)
    $pm run lint $argv
end
