function nt --description "pm run test"
    set -l pm (_pm)
    $pm run test $argv
end
