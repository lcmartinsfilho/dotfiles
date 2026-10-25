return {
  {
    "linux-cultist/venv-selector.nvim",
    branch = "main",
    ft = "python",
    cmd = "VenvSelect",
    dependencies = { "neovim/nvim-lspconfig", "nvim-telescope/telescope.nvim" },
    keys = { { "<leader>vs", "<cmd>VenvSelect<cr>", desc = "Select virtualenv" } },
    opts = {},
  },
}
