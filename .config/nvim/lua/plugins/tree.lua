return {
  {
    "nvim-neo-tree/neo-tree.nvim",
    branch = "v3.x",
    cmd = "Neotree",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "echasnovski/mini.icons",
      "MunifTanjim/nui.nvim",
    },
    keys = {
      { "<leader>t", "<cmd>Neotree toggle<cr>", desc = "File tree" },
      { "<leader>T", "<cmd>Neotree reveal<cr>", desc = "Reveal file in tree" },
    },
    opts = {
      filesystem = {
        filtered_items = { visible = true, hide_dotfiles = false },
        follow_current_file = { enabled = true },
        hijack_netrw_behavior = "disabled",
      },
      window = { width = 32 },
    },
  },
}
