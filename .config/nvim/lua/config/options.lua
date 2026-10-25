local opt = vim.opt

-- Unused remote-plugin providers (silences :checkhealth warnings)
for _, p in ipairs({ "node", "perl", "ruby", "python3" }) do
  vim.g["loaded_" .. p .. "_provider"] = 0
end

opt.number = true
opt.relativenumber = true
opt.signcolumn = "yes"
opt.cursorline = true
opt.scrolloff = 8
opt.termguicolors = true

opt.expandtab = true
opt.shiftwidth = 2
opt.tabstop = 2
opt.smartindent = true

opt.ignorecase = true
opt.smartcase = true
opt.undofile = true
opt.updatetime = 250
opt.splitright = true
opt.splitbelow = true
opt.clipboard = "unnamedplus"

-- English + Brazilian Portuguese spell checking (harper-ls is English-only)
opt.spelllang = { "en_us", "pt_br" }

-- Word count in the statusline (selection-aware)
function _G.WordCount()
  local wc = vim.fn.wordcount()
  if wc.visual_words then
    return wc.visual_words .. "/" .. wc.words .. " words"
  end
  return wc.words .. " words"
end
opt.laststatus = 2
opt.statusline = "%f %m%r%=%{v:lua.WordCount()}  %l:%c  %p%%"

vim.diagnostic.config({
  severity_sort = true,
  float = { border = "rounded" },
  virtual_text = { spacing = 2 },
})
