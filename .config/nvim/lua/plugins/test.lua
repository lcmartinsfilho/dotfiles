return {
  {
    "nvim-neotest/neotest",
    dependencies = {
      "nvim-neotest/nvim-nio",
      "nvim-lua/plenary.nvim",
      "antoinemadec/FixCursorHold.nvim",
      "nvim-treesitter/nvim-treesitter",
      "nvim-neotest/neotest-python",
      "nvim-neotest/neotest-jest",
      "marilari88/neotest-vitest",
      "alfaix/neotest-gtest",
      "mrcjkb/rustaceanvim",
    },
    keys = {
      { "<leader>tt", function() require("neotest").run.run() end, desc = "Run nearest test" },
      { "<leader>tf", function() require("neotest").run.run(vim.fn.expand("%")) end, desc = "Run file tests" },
      { "<leader>tl", function() require("neotest").run.run_last() end, desc = "Run last test" },
      { "<leader>td", function() require("neotest").run.run({ strategy = "dap" }) end, desc = "Debug nearest test" },
      { "<leader>ts", function() require("neotest").summary.toggle() end, desc = "Test summary" },
      { "<leader>to", function() require("neotest").output.open({ enter = true }) end, desc = "Test output" },
      { "<leader>tO", function() require("neotest").output_panel.toggle() end, desc = "Test output panel" },
    },
    config = function()
      require("neotest").setup({
        adapters = {
          require("rustaceanvim.neotest"),
          require("neotest-python"),
          require("neotest-jest"),
          require("neotest-vitest"),
          require("neotest-gtest").setup({}),
        },
      })
    end,
  },
  {
    "stevearc/overseer.nvim",
    cmd = { "OverseerRun", "OverseerToggle", "OverseerTaskAction" },
    keys = {
      { "<leader>or", "<cmd>OverseerRun<cr>", desc = "Run task" },
      { "<leader>ot", "<cmd>OverseerToggle<cr>", desc = "Task list" },
    },
    opts = {},
  },
}
