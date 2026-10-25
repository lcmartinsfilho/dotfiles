-- Language servers + the tools mason installs for them.
-- rust-analyzer is handled by rustaceanvim (see rust.lua), not enabled here.
return {
  {
    "williamboman/mason.nvim",
    lazy = false,
    opts = {},
  },
  {
    "WhoIsSethDaniel/mason-tool-installer.nvim",
    dependencies = { "williamboman/mason.nvim" },
    opts = {
      ensure_installed = {
        -- language servers
        "basedpyright", "ruff", "vtsls", "eslint-lsp", "lua-language-server",
        "ltex-ls-plus", "clangd",
        -- formatters
        "prettier", "clang-format", "stylua",
        -- debug adapters
        "codelldb", "debugpy", "js-debug-adapter",
      },
    },
  },
  {
    "neovim/nvim-lspconfig",
    dependencies = { "saghen/blink.cmp" },
    config = function()
      -- Give every server blink.cmp's completion capabilities
      vim.lsp.config("*", {
        capabilities = require("blink.cmp").get_lsp_capabilities(),
      })

      vim.lsp.config("lua_ls", {
        settings = {
          Lua = {
            runtime = { version = "LuaJIT" },
            diagnostics = { globals = { "vim" } },
            workspace = { checkThirdParty = false, library = { vim.env.VIMRUNTIME } },
            telemetry = { enable = false },
          },
        },
      })

      -- ruff handles lint/format/imports; leave hover to basedpyright
      vim.lsp.config("ruff", {
        on_attach = function(client) client.server_capabilities.hoverProvider = false end,
      })

      vim.lsp.config("clangd", {
        cmd = {
          "clangd", "--background-index", "--clang-tidy",
          "--header-insertion=iwyu", "--completion-style=detailed",
        },
      })

      -- LanguageTool grammar for English + Brazilian Portuguese (replaces harper-ls, which is English-only).
      -- "auto" detects the language per document; set "pt-BR" or "en-US" to force one.
      vim.lsp.config("ltex_plus", {
        filetypes = { "markdown", "text", "tex", "gitcommit", "rst" },
        -- Empty JAVA_HOME makes the launcher use its bundled JDK (the shell's one is stale)
        cmd_env = { JAVA_HOME = "" },
        settings = {
          ltex = {
            language = "auto",
            additionalRules = { enablePickyRules = false },
          },
        },
      })

      vim.lsp.enable({
        "basedpyright", "ruff", "vtsls", "eslint", "clangd", "lua_ls",
        "ltex_plus",
      })
    end,
  },
}
