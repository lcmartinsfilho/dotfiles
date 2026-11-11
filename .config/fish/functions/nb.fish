function nb --description "pm run build"
    set -l pm (_pm)
    $pm run build $argv
end
