function fish_should_add_to_history --description 'Skip leading-space commands and ones that set secrets'
    string match -qr '^\s' -- $argv[1]; and return 1
    string match -qr '(KEY|TOKEN|SECRET|PASSWORD)\S*=' -- $argv[1]; and return 1
    return 0
end
