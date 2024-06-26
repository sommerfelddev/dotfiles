local opt = vim.opt

opt.undofile = true
opt.swapfile = false
opt.shadafile = "NONE"

opt.number = true
opt.cursorline = true
opt.signcolumn = "auto:2"
opt.showmatch = true

opt.expandtab = true
opt.shiftround = true
opt.shiftwidth = 0
opt.softtabstop = -1
opt.tabstop = 4

opt.splitbelow = true
opt.splitright = true

opt.linebreak = true
opt.breakindent = true
opt.textwidth = 80
opt.colorcolumn = "+1"
opt.formatoptions:remove("t")

opt.cmdheight = 2

opt.shortmess:append({ a = true })

opt.gdefault = true
opt.synmaxcol = 500

opt.completeopt = { "menu", "menuone", "noselect" }
opt.scrolloff = 999
opt.sidescrolloff = 5

opt.clipboard = "unnamedplus"

opt.wildmode = { "longest", "full" }

opt.cpoptions:remove({ "_" })

opt.listchars = {
  tab = "> ",
  trail = "·",
  extends = ">",
  precedes = "<",
  nbsp = "+",
}
opt.list = true

opt.virtualedit = "block"
opt.spelloptions = "camel"

vim.g.is_posix = 1
vim.g.python_host_prog = 0
vim.g.python3_host_prog = 0
vim.g.netrw_home = vim.fn.stdpath("data")

opt.diffopt:append({
  ["indent-heuristic"] = true,
  hiddenoff = true,
  iblank = true,
  iwhiteall = true,
  algorithm = "histogram",
})

if vim.fn.executable("rg") then
  opt.grepprg = "rg\\ --vimgrep"
  opt.grepformat:append("f:%l:%c:%m")
end

opt.termguicolors = true
opt.pumblend = 20

opt.foldmethod = "expr"
opt.foldexpr = "nvim_treesitter#foldexpr()"
opt.foldenable = false

vim.g.mapleader = " "
vim.g.maplocalleader = ","

vim.diagnostic.config({
  virtual_text = {
    source = "if_many",
    severity = vim.diagnostic.severity.ERROR,
  }
})
