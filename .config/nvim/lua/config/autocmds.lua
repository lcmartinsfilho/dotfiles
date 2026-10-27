local aug = vim.api.nvim_create_augroup("user-autocmds", { clear = true })

-- Spell checking for prose-like filetypes
vim.api.nvim_create_autocmd("FileType", {
  group = aug,
  pattern = { "markdown", "text", "tex", "gitcommit" },
  callback = function() vim.opt_local.spell = true end,
})

-- Briefly highlight yanked text
vim.api.nvim_create_autocmd("TextYankPost", {
  group = aug,
  callback = function() vim.hl.on_yank() end,
})

-- Per-language indentation
vim.api.nvim_create_autocmd("FileType", {
  group = aug,
  pattern = { "rust", "python", "c", "cpp" },
  callback = function()
    vim.opt_local.shiftwidth = 4
    vim.opt_local.tabstop = 4
  end,
})

-- Word-processor style soft wrapping for markdown
vim.api.nvim_create_autocmd("FileType", {
  group = aug,
  pattern = "markdown",
  callback = function()
    vim.opt_local.wrap = true
    vim.opt_local.linebreak = true
    vim.opt_local.breakindent = true
    vim.keymap.set({ "n", "v" }, "j", "gj", { buffer = true })
    vim.keymap.set({ "n", "v" }, "k", "gk", { buffer = true })
  end,
})
