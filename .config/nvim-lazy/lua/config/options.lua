-- Loaded by LazyVim after its own defaults. Only deviations from LazyVim.
local opt = vim.opt

for _, p in ipairs({ "node", "perl", "ruby", "python3" }) do
  vim.g["loaded_" .. p .. "_provider"] = 0
end

opt.relativenumber = true
opt.clipboard = "unnamedplus"
opt.spelllang = { "en_us", "pt_br" }
opt.shiftwidth = 2
opt.tabstop = 2
