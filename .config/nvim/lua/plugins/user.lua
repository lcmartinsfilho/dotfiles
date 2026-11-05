local is_bsd = vim.uv.os_uname().sysname == "FreeBSD"

return {
  -- Oil alongside the snacks explorer
  {
    "stevearc/oil.nvim",
    lazy = false,
    keys = { { "-", "<cmd>Oil<cr>", desc = "Open parent directory" } },
    opts = {
      view_options = { show_hidden = true },
      keymaps = { ["q"] = "actions.close" },
    },
  },

  -- Rust: rust-analyzer comes from rustup (not mason); run clippy instead of cargo check on save
  {
    "mrcjkb/rustaceanvim",
    opts = {
      server = {
        default_settings = {
          ["rust-analyzer"] = { check = { command = "clippy" } },
        },
      },
    },
  },

  -- Prose: LanguageTool (EN + pt-BR) and pandoc
  {
    "neovim/nvim-lspconfig",
    opts = function(_, opts)
      -- FreeBSD: mason has no binaries, so these servers come from pkg(8)/npm on PATH.
      -- mason = false makes LazyVim enable them without asking mason to install them.
      if is_bsd then
        for _, name in ipairs({ "basedpyright", "ruff", "clangd", "lua_ls", "ltex_plus" }) do
          opts.servers[name] = vim.tbl_deep_extend("force", opts.servers[name] or {}, { mason = false })
        end
      end
    end,
  },
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        ltex_plus = {
          filetypes = { "markdown", "text", "tex", "gitcommit", "rst" },
          cmd_env = { JAVA_HOME = is_bsd and "/usr/local/openjdk21" or "" },
          settings = {
            ltex = { language = "auto", additionalRules = { enablePickyRules = false } },
          },
        },
      },
    },
  },
  {
    "aspeddro/pandoc.nvim",
    ft = { "markdown", "text", "tex", "rst" },
    cmd = "Pandoc",
    config = function() require("pandoc").setup() end,
  },

  -- Mason: FreeBSD only gets the npm-based tools (the rest comes from pkg, see scripts/os/freebsd.sh)
  {
    "mason-org/mason.nvim",
    opts = function(_, opts)
      if is_bsd then
        opts.ensure_installed = { "vtsls", "eslint-lsp", "prettier", "js-debug-adapter" }
      end
    end,
  },
}
