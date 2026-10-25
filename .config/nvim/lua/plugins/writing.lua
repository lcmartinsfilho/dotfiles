-- Prose tooling: pandoc conversion (harper-ls is configured in lsp.lua)
return {
  {
    -- :Pandoc <args> converts the current file (needs the pandoc binary)
    "aspeddro/pandoc.nvim",
    ft = { "markdown", "text", "tex", "rst" },
    cmd = "Pandoc",
    config = function() require("pandoc").setup() end,
  },
}
