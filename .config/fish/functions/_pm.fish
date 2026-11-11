function _pm --description 'Detect node package manager from lockfile (pnpm > yarn > npm)'
    set -l d $PWD
    while test $d != /
        test -f $d/pnpm-lock.yaml; and echo pnpm; and return
        test -f $d/yarn.lock; and echo yarn; and return
        test -f $d/package-lock.json; and echo npm; and return
        set d (string replace -r '/[^/]*$' '' -- $d)
        test -n "$d"; or set d /
    end
    echo npm
end
