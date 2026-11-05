local aug = vim.api.nvim_create_augroup("user-autocmds", { clear = true })

vim.api.nvim_create_autocmd("FileType", {
  group = aug,
  pattern = { "rust", "python", "c", "cpp" },
  callback = function()
    vim.opt_local.shiftwidth = 4
    vim.opt_local.tabstop = 4
  end,
})

vim.api.nvim_create_autocmd("FileType", {
  group = aug,
  pattern = { "text", "tex", "gitcommit" },
  callback = function() vim.opt_local.spell = true end,
})
