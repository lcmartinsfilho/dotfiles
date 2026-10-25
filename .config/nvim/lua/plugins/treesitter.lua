-- Uses the `main` branch (needs the tree-sitter CLI: brew install tree-sitter-cli)
return {
  {
    "nvim-treesitter/nvim-treesitter",
    branch = "main",
    lazy = false,
    build = ":TSUpdate",
    config = function()
      local ensure = {
        "rust", "toml", "python", "javascript", "typescript", "tsx", "json",
        "c", "cpp", "cmake", "make", "lua", "vim", "vimdoc", "bash",
        "markdown", "markdown_inline", "yaml", "html", "css", "regex", "query",
      }
      require("nvim-treesitter").install(ensure)

      -- Highlighting and indentation for any filetype with an installed parser
      vim.api.nvim_create_autocmd("FileType", {
        group = vim.api.nvim_create_augroup("user-treesitter", { clear = true }),
        callback = function(ev)
          if pcall(vim.treesitter.start, ev.buf) then
            vim.bo[ev.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
          end
        end,
      })
    end,
  },
  {
    "nvim-treesitter/nvim-treesitter-textobjects",
    branch = "main",
    event = "VeryLazy",
    config = function()
      require("nvim-treesitter-textobjects").setup({ select = { lookahead = true } })
      local select = require("nvim-treesitter-textobjects.select")
      for key, query in pairs({
        af = "@function.outer", ["if"] = "@function.inner",
        ac = "@class.outer", ic = "@class.inner",
        aa = "@parameter.outer", ia = "@parameter.inner",
      }) do
        vim.keymap.set({ "x", "o" }, key, function()
          select.select_textobject(query, "textobjects")
        end, { desc = "Select " .. query })
      end
    end,
  },
}
