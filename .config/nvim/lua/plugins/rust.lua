return {
  {
    -- Configures rust-analyzer itself; do not also enable it via vim.lsp.enable
    "mrcjkb/rustaceanvim",
    version = "^6",
    lazy = false, -- the plugin lazy-loads itself on rust filetypes
    init = function()
      vim.g.rustaceanvim = {
        server = {
          default_settings = {
            ["rust-analyzer"] = {
              check = { command = "clippy" },
              cargo = { allFeatures = true },
            },
          },
          on_attach = function(_, bufnr)
            local function map(keys, cmd, desc)
              vim.keymap.set("n", keys, function() vim.cmd.RustLsp(cmd) end,
                { buffer = bufnr, desc = "Rust: " .. desc })
            end
            map("<leader>rr", "runnables", "Runnables")
            map("<leader>rt", "testables", "Testables")
            map("<leader>rd", "debuggables", "Debuggables")
            map("<leader>rm", "expandMacro", "Expand macro")
            map("<leader>re", "explainError", "Explain error")
            map("<leader>rc", "openCargo", "Open Cargo.toml")
            map("<leader>rp", "parentModule", "Parent module")
            -- Override K with the richer hover actions
            vim.keymap.set("n", "K", function() vim.cmd.RustLsp({ "hover", "actions" }) end,
              { buffer = bufnr, desc = "Rust: hover actions" })
          end,
        },
      }
    end,
  },
  {
    "saecki/crates.nvim",
    event = "BufRead Cargo.toml",
    opts = {
      lsp = {
        enabled = true,
        actions = true,
        completion = true,
        hover = true,
      },
    },
  },
}
