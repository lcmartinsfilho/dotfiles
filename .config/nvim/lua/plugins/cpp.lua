return {
  {
    "p00f/clangd_extensions.nvim",
    ft = { "c", "cpp" },
    config = function()
      require("clangd_extensions").setup({})
      vim.api.nvim_create_autocmd("FileType", {
        pattern = { "c", "cpp" },
        callback = function(ev)
          vim.keymap.set("n", "<leader>ch", "<cmd>LspClangdSwitchSourceHeader<cr>",
            { buffer = ev.buf, desc = "Switch source/header" })
          vim.keymap.set("n", "<leader>ct", "<cmd>ClangdTypeHierarchy<cr>",
            { buffer = ev.buf, desc = "Type hierarchy" })
        end,
      })
    end,
  },
}
