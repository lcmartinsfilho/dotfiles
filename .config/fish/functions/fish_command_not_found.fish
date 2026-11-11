function fish_command_not_found --description 'cd into a directory typed as a bare name (like zsh auto_cd)'
    if test (count $argv) -eq 1; and test -d $argv[1]
        cd $argv[1]
    else
        __fish_default_command_not_found_handler $argv
    end
end
