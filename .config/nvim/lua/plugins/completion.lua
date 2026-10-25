return {
  {
    "saghen/blink.cmp",
    version = "1.*",
    dependencies = { "rafamadriz/friendly-snippets" },
    event = { "InsertEnter", "CmdlineEnter" },
    opts = {
      keymap = { preset = "default" }, -- <C-y> accept, <C-space> menu, <C-e> close
      appearance = { nerd_font_variant = "mono" },
      completion = { documentation = { auto_show = true, auto_show_delay_ms = 300 } },
      signature = { enabled = true },
      sources = { default = { "lsp", "path", "snippets", "buffer" } },
    },
  },
}
