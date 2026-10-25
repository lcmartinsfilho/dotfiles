local map = vim.keymap.set

-- Diagnostics ([d / ]d are also Neovim defaults; kept explicit)
map("n", "[d", function() vim.diagnostic.jump({ count = -1, float = true }) end, { desc = "Prev diagnostic" })
map("n", "]d", function() vim.diagnostic.jump({ count = 1, float = true }) end, { desc = "Next diagnostic" })
map("n", "<leader>e", vim.diagnostic.open_float, { desc = "Diagnostic float" })

-- LSP keymaps, set per buffer when a server attaches.
-- Neovim 0.11+ already provides: grn rename, gra code action, grr references,
-- gri implementation, gO symbols, K hover, <C-s> signature help (insert).
vim.api.nvim_create_autocmd("LspAttach", {
  group = vim.api.nvim_create_augroup("user-lsp-attach", { clear = true }),
  callback = function(ev)
    local function lmap(keys, fn, desc, mode)
      map(mode or "n", keys, fn, { buffer = ev.buf, desc = "LSP: " .. desc })
    end
    lmap("gd", vim.lsp.buf.definition, "Go to definition")
    lmap("gD", vim.lsp.buf.declaration, "Go to declaration")
    lmap("gy", vim.lsp.buf.type_definition, "Go to type definition")
    lmap("<leader>rn", vim.lsp.buf.rename, "Rename")
    lmap("<leader>ca", vim.lsp.buf.code_action, "Code action", { "n", "v" })

    local client = vim.lsp.get_client_by_id(ev.data.client_id)
    if client and client:supports_method("textDocument/inlayHint") then
      lmap("<leader>ih", function()
        vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled({ bufnr = ev.buf }), { bufnr = ev.buf })
      end, "Toggle inlay hints")
    end
  end,
})

-- Window / buffer basics
map("n", "<Esc>", "<cmd>nohlsearch<CR>")
map("n", "<leader>w", "<cmd>write<CR>", { desc = "Write" })
map("n", "<leader>q", "<cmd>quit<CR>", { desc = "Quit" })
