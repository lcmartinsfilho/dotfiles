-- LazyVim defaults are kept (<leader>w windows, <leader>q session, <leader>e explorer).
local map = vim.keymap.set
map("n", "<leader>cD", vim.diagnostic.open_float, { desc = "Diagnostic float" })
