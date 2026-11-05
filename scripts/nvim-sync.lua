-- Headless sync of Neovim plugins and mason packages. Used by update.sh / install-deps.sh:
--   nvim --headless "+Lazy! sync" "+luafile scripts/nvim-sync.lua" +qa
-- LazyVim installs mason packages lazily and asynchronously, which a headless run would abort,
-- so this installs the configured ensure_installed list, upgrades outdated ones, and waits.
local ok, lazy = pcall(require, "lazy")
if not ok then return end
lazy.load({ plugins = { "mason.nvim", "mason-lspconfig.nvim", "nvim-lspconfig" } })

local registry = require("mason-registry")
local plugin = require("lazy.core.config").plugins["mason.nvim"]
local opts = require("lazy.core.plugin").values(plugin, "opts", false)
local wanted = type(opts) == "table" and opts.ensure_installed or {}

local refreshed = false
registry.update(function() refreshed = true end)
vim.wait(60000, function() return refreshed end, 100)

local pending = 0
local function finish() pending = pending - 1 end  -- callback runs when the install ends, ok or not

for _, name in ipairs(wanted) do
  local found, pkg = pcall(registry.get_package, name)
  if not found then
    vim.notify("mason: unknown package " .. name, vim.log.levels.WARN)
  elseif pkg:is_installing() then
    -- LazyVim already kicked this one off; just wait for it below.
  elseif not pkg:is_installed() or pkg:get_installed_version() ~= pkg:get_latest_version() then
    -- Not installed yet, or the registry has a newer version: (re)install the latest.
    pending = pending + 1
    pkg:install({}, function() finish() end)
  end
end

-- LazyVim starts its own installs (LSP servers via mason-lspconfig, ensure_installed) shortly after
-- mason loads, so give those a moment to begin, then wait for every install to finish.
local function busy()
  if pending > 0 then return true end
  for _, pkg in ipairs(registry.get_all_packages()) do
    if pkg:is_installing() then return true end
  end
  return false
end
vim.wait(5000)
vim.wait(15 * 60 * 1000, function() return not busy() end, 200)
