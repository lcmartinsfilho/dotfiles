-- Language servers + the tools mason installs for them.
-- rust-analyzer is handled by rustaceanvim (see rust.lua), not enabled here.
-- Mason has no FreeBSD binaries (and no python3 there); on FreeBSD only the
-- npm-based tools install via mason, the rest come from pkg(8) on PATH.
local is_bsd = vim.uv.os_uname().sysname == "FreeBSD"

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
      ensure_installed = is_bsd and {
        "vtsls", "eslint-lsp", "prettier", "js-debug-adapter",
      } or {
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
        -- FreeBSD uses the generic tarball, which has no bundled JDK: point at pkg's OpenJDK
        cmd_env = { JAVA_HOME = is_bsd and "/usr/local/openjdk21" or "" },
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
