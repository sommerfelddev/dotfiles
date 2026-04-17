local opt = vim.o

opt.undofile = true
opt.swapfile = false
opt.shadafile = "NONE"

opt.number = true
opt.cursorline = true
opt.signcolumn = "auto:2"
opt.showmatch = true
opt.laststatus = 3

opt.expandtab = true
opt.shiftround = true
opt.shiftwidth = 0
opt.softtabstop = -1
opt.tabstop = 4

opt.gdefault = true
opt.ignorecase = true
opt.smartcase = true

opt.splitbelow = true
opt.splitright = true
opt.splitkeep = "screen"

opt.linebreak = true
opt.breakindent = true
opt.textwidth = 80
opt.colorcolumn = "+1"
vim.opt.formatoptions:remove("t")

opt.cmdheight = 2
-- vim.o.messagesopt = "wait:5000,history:500"

vim.opt.shortmess:append({ a = true })

opt.updatetime = 250
opt.timeoutlen = 300
opt.synmaxcol = 500

vim.opt.completeopt = { "menuone", "noselect", "popup", "fuzzy" }
opt.scrolloff = 999
opt.sidescrolloff = 5

vim.schedule(function()
  opt.clipboard = vim.env.SSH_TTY and "" or "unnamedplus"
end)

vim.o.mouse = "a"

vim.opt.wildmode = { "longest", "full" }

vim.opt.cpoptions:remove({ "_" })

vim.opt.listchars = {
  tab = "> ",
  space = "·",
  extends = ">",
  precedes = "<",
  nbsp = "+",
}
opt.list = true

opt.confirm = true

opt.virtualedit = "block"
opt.spelloptions = "camel"

vim.g.loaded_node_provider = 0
vim.g.loaded_perl_provider = 0
vim.g.loaded_python3_provider = 0

vim.opt.diffopt:append({
  hiddenoff = true,
  iblank = true,
  iwhiteall = true,
  algorithm = "histogram",
})

if vim.fn.executable("rg") then
  opt.grepprg = "rg\\ --vimgrep"
  opt.grepformat = "f:%l:%c:%m"
end

opt.pumblend = 20

vim.wo.foldmethod = "expr"
vim.wo.foldenable = false

vim.g.mapleader = " "
vim.g.maplocalleader = ","

vim.diagnostic.config({
  virtual_text = false,
  virtual_lines = false,
})

opt.sessionoptions =
  "blank,buffers,curdir,help,tabpages,winsize,winpos,terminal,localoptions"

vim.o.exrc = true


