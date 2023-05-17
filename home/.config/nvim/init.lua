vim.loader.enable()

function docfg(name)
  dofile(vim.fn.stdpath("config") .. "/lua/cfg/" .. name .. ".lua")
end

docfg("options")

function P(v)
  print(vim.inspect(v))
  return v
end

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable", -- latest stable release
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)
require("lazy").setup("custom.plugins")
