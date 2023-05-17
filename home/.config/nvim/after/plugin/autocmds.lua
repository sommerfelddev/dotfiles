local function augroup(name)
  return vim.api.nvim_create_augroup(name, {})
end

local autocmd = vim.api.nvim_create_autocmd

-- adapted from https://github.com/ethanholz/nvim-lastplace/blob/main/lua/nvim-lastplace/init.lua
local ignore_buftype = { "quickfix", "nofile", "help" }
local ignore_filetype = { "gitcommit", "gitrebase", "svn", "hgcommit" }

local function run()
  if vim.tbl_contains(ignore_buftype, vim.bo.buftype) then
    return
  end

  if vim.tbl_contains(ignore_filetype, vim.bo.filetype) then
    -- reset cursor to first line
    vim.cmd [[normal! gg]]
    return
  end

  -- If a line has already been specified on the command line, we are done
  --   nvim file +num
  if vim.fn.line(".") > 1 then
    return
  end

  local last_line = vim.fn.line([['"]])
  local buff_last_line = vim.fn.line("$")

  -- If the last line is set and the less than the last line in the buffer
  if last_line > 0 and last_line <= buff_last_line then
    local win_last_line = vim.fn.line("w$")
    local win_first_line = vim.fn.line("w0")
    -- Check if the last line of the buffer is the same as the win
    if win_last_line == buff_last_line then
      -- Set line to last line edited
      vim.cmd [[normal! g`"]]
      -- Try to center
    elseif buff_last_line - last_line >
        ((win_last_line - win_first_line) / 2) - 1 then
      vim.cmd [[normal! g`"zz]]
    else
      vim.cmd [[normal! G'"<c-e>]]
    end
  end
end

augroup("restore position")
autocmd("BufReadPost", {
  once = true,
  group = "restore position",
  callback = run
})

augroup("postwrite")
autocmd("BufWritePost", {
  group = "postwrite",
  pattern = ".Xkeymap",
  command = "!xkbcomp % $DISPLAY",
})
autocmd("BufWritePost", {
  group = "postwrite",
  pattern = "*bspwmrc",
  command = "!bspc wm --restart",
})
autocmd("BufWritePost", {
  group = "postwrite",
  pattern = "*/polybar/config",
  command = "!polybar-msg cmd restart",
})
autocmd("BufWritePost", {
  group = "postwrite",
  pattern = "user-dirs.dirs,user-dirs.locale",
  command = "!xdg-user-dirs-update",
})
autocmd("BufWritePost", {
  group = "postwrite",
  pattern = "plugins.lua",
  command = "source % | PackerSync",
})
autocmd("BufWritePost", {
  group = "postwrite",
  pattern = "dunstrc",
  command = "!killall -SIGUSR2 dunst",
})
autocmd(
  "BufWritePost",
  { group = "postwrite", pattern = "fonts.conf", command = "!fc-cache" }
)

augroup("autocomplete")
autocmd("CompleteDone", {
  group = "autocomplete",
  command = "if pumvisible() == 0 | silent! pclose | endif",
})

augroup("reload")
autocmd("CompleteDone", {
  group = "reload",
  command = "if getcmdwintype() == '' | checktime | endif",
})

augroup("highlightyank")
autocmd(
  "TextYankPost",
  { group = "highlightyank", callback = vim.highlight.on_yank }
)

augroup("quitro")
autocmd("BufReadPost", {
  group = "quitro",
  callback = function()
    if vim.opt.readonly:get() then
      vim.keymap.set("n", "q", "<cmd>q<cr>")
    end
  end,
})

augroup("localinit")
autocmd("VimEnter", {
  group = "localinit",
  callback = function()
    local settings = vim.fn.findfile(".doit.lua", ".;")
    if settings ~= "" then
      print("sourcing local config")
      dofile(settings)
    end
  end,
})

augroup("restore guicursor")
autocmd("VimLeave", {
  once = true,
  group = "restore guicursor",
  command = 'set guicursor= | call chansend(v:stderr, "\x1b[ q")'
})
