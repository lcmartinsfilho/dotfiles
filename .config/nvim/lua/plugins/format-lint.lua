return {
  {
    "stevearc/conform.nvim",
    event = "BufWritePre",
    cmd = "ConformInfo",
    keys = {
      { "<leader>cf", function() require("conform").format({ async = true, lsp_format = "fallback" }) end,
        desc = "Format buffer" },
    },
    opts = {
      formatters_by_ft = {
        rust = { "rustfmt" },
        python = { "ruff_organize_imports", "ruff_format" },
        javascript = { "prettier" },
        javascriptreact = { "prettier" },
        typescript = { "prettier" },
        typescriptreact = { "prettier" },
        json = { "prettier" },
        css = { "prettier" },
        html = { "prettier" },
        yaml = { "prettier" },
        markdown = { "prettier" },
        c = { "clang-format" },
        cpp = { "clang-format" },
        lua = { "stylua" },
      },
      format_on_save = { timeout_ms = 1000, lsp_format = "fallback" },
    },
  },
  {
    -- Linters without an LSP. eslint/ruff/clippy/clangd-tidy come through their servers.
    "mfussenegger/nvim-lint",
    event = { "BufReadPost", "BufWritePost" },
    config = function()
      require("lint").linters_by_ft = {
        -- add entries here, e.g. sh = { "shellcheck" }
      }
      vim.api.nvim_create_autocmd({ "BufWritePost", "BufReadPost" }, {
        group = vim.api.nvim_create_augroup("user-lint", { clear = true }),
        callback = function() require("lint").try_lint() end,
      })
    end,
  },
}
