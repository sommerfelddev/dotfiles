local opt = vim.o

-- Persistence
opt.undofile = true -- persist undo history across sessions
opt.swapfile = false -- no swap files; rely on undofile for recovery

-- Gutter
opt.number = true -- show line numbers
opt.cursorline = true -- highlight current line
opt.signcolumn = "auto:2" -- up to 2 sign columns, auto-hide when empty
opt.laststatus = 3 -- single global statusline

-- Indentation (defaults; guess-indent overrides per-buffer)
opt.expandtab = true -- spaces instead of tabs
opt.shiftround = true -- round indent to shiftwidth multiples
opt.shiftwidth = 0 -- follow tabstop value
opt.softtabstop = -1 -- follow shiftwidth value
opt.tabstop = 4 -- 4-space tabs

-- Search
opt.gdefault = true -- substitute all matches per line by default
opt.ignorecase = true -- case-insensitive search
opt.smartcase = true -- ...unless query has uppercase

-- Splits
opt.splitbelow = true -- horizontal splits open below
opt.splitright = true -- vertical splits open right
opt.splitkeep = "screen" -- keep text position stable on split

-- Line wrapping
opt.linebreak = true -- wrap at word boundaries
opt.breakindent = true -- indent wrapped lines
opt.textwidth = 80 -- wrap column for formatting
opt.colorcolumn = "+1" -- highlight column after textwidth
vim.opt.formatoptions:remove("t") -- don't auto-wrap text while typing

-- Messages
opt.messagesopt = "wait:5000,history:500" -- message display timing and history depth

vim.opt.shortmess:append({ a = true }) -- abbreviate all file messages

-- Timing
opt.updatetime = 250 -- CursorHold delay (ms); affects gitsigns, diagnostics
opt.timeoutlen = 300 -- key sequence timeout (ms); affects which-key popup delay

-- Completion and scrolling
vim.opt.completeopt = { "menuone", "noselect", "popup", "fuzzy", "nearest" }
opt.scrolloff = 999 -- keep cursor vertically centered
opt.sidescrolloff = 5 -- horizontal scroll margin

-- Clipboard (deferred to avoid blocking startup on clipboard detection)
vim.schedule(function()
  opt.clipboard = vim.env.SSH_TTY and "" or "unnamedplus"
end)

opt.mouse = "a" -- enable mouse in all modes

vim.opt.wildmode = { "longest", "full" } -- cmdline completion: longest match, then full menu

vim.opt.cpoptions:remove({ "_" }) -- cw changes to end of word (not compatible vi behavior)

-- Visible whitespace
vim.opt.listchars = {
  tab = "> ",
  space = "·",
  extends = ">",
  precedes = "<",
  nbsp = "+",
}
opt.list = true -- show whitespace characters

opt.confirm = true -- confirm before closing unsaved buffers

opt.virtualedit = "block" -- allow cursor past end of line in visual block
opt.spelloptions = "camel" -- treat camelCase words as separate words for spell check

-- Disable unused providers
vim.g.loaded_node_provider = 0
vim.g.loaded_perl_provider = 0
vim.g.loaded_python3_provider = 0

-- Diff
vim.opt.diffopt:append({
  hiddenoff = true, -- disable diff on hidden buffers
  iblank = true, -- ignore blank line changes
  iwhiteall = true, -- ignore all whitespace changes
  algorithm = "histogram", -- better diff algorithm
})

-- Use ripgrep for :grep
if vim.fn.executable("rg") then
  opt.grepprg = "rg\\ --vimgrep"
  opt.grepformat = "%f:%l:%c:%m"
end

-- Popup and window borders
opt.pumblend = 20 -- popup menu transparency
opt.pumborder = "rounded"
opt.winborder = "rounded" -- default border for floating windows

-- Folding: set up treesitter-based folds but start with them closed.
-- Autocmd in autocmds.lua sets foldexpr per-buffer when treesitter is available.
vim.o.foldmethod = "expr"
vim.o.foldenable = false

vim.g.mapleader = " "
vim.g.maplocalleader = ","

-- Session persistence (for auto-session)
opt.sessionoptions =
  "blank,buffers,curdir,help,tabpages,winsize,winpos,terminal,localoptions"

opt.exrc = true -- source project-local .nvim.lua files
