local function map(mode, l, r, desc)
  vim.keymap.set(mode, l, r, { desc = desc })
end
local function cmd(mode, l, r, desc)
  map(mode, l, "<cmd>" .. r .. "<cr>", desc)
end
local function cmdi(mode, l, r, desc)
  map(mode, l, ":" .. r, desc)
end
local function nmap(l, r, desc)
  map("n", l, r, desc)
end
local function vmap(l, r, desc)
  map("v", l, r, desc)
end
local function nvmap(l, r, desc)
  map({ "n", "v" }, l, r, desc)
end
local function ncmd(l, r, desc)
  cmd("n", l, r, desc)
end
local function ncmdi(l, r, desc)
  cmdi("n", l, r, desc)
end
local function vcmdi(l, r, desc)
  cmdi("v", l, r, desc)
end

ncmd("<esc>", "nohlsearch")

nmap("<Space>", "<Nop>")

-- make an accidental ; press also enter command mode
nmap(";", ":")

-- highlight last inserted text
nmap("gV", "`[v`]")

nmap("<down>", "<c-e>")
nmap("<up>", "<c-y>")

-- go to first non-blank character of current line
nvmap("<c-a>", "^")
nvmap("<c-e>", "$")

-- This extends p in visual mode (note the noremap), so that if you paste from
-- the unnamed (ie. default) register, that register content is not replaced by
-- the visual selection you just pasted over–which is the default behavior.
-- This enables the user to yank some text and paste it over several places in
-- a row, without using a named register
-- map.v('p', "p:if v:register == '"'<Bar>let @@=@0<Bar>endif<cr>")
vmap("p", 'p:let @+=@0<CR>:let @"=@0<CR>')

-- Find and Replace binds
ncmdi("<localleader>s", "%s/")
vcmdi("<localleader>s", "s/")

ncmd("<leader>x", "wall")
ncmd("<leader>z", "wqall")
ncmd("<leader>q", "quitall")

vim.keymap.set(
  "t",
  "<esc><esc>",
  "<c-\\><c-n>",
  { silent = true, noremap = true, desc = "Exit terminal mode" }
)

nmap("[w", function()
  vim.diagnostic.jump({
    count = -vim.v.count1,
    severity = { min = vim.diagnostic.severity.WARN },
  })
end)
nmap("]w", function()
  vim.diagnostic.jump({
    count = vim.v.count1,
    severity = { min = vim.diagnostic.severity.WARN },
  })
end)
nmap("[e", function()
  vim.diagnostic.jump({
    count = -vim.v.count1,
    severity = vim.diagnostic.severity.ERROR,
  })
end)
nmap("]e", function()
  vim.diagnostic.jump({
    count = vim.v.count1,
    severity = vim.diagnostic.severity.ERROR,
  })
end)

nmap(
  "<leader>oq",
  vim.diagnostic.setloclist,
  "[O]pen diagnostic [Q]uickfix list"
)

nmap("yp", function()
  vim.fn.setreg("+", vim.fn.expand("%"))
end, "[Y]ank [P]ath")

local doas_exec = function(_cmd)
  vim.fn.inputsave()
  local password = vim.fn.inputsecret("Password: ")
  vim.fn.inputrestore()
  if not password or #password == 0 then
    vim.notify("Invalid password, doas aborted", vim.log.levels.WARN)
    return false
  end
  local out = vim.fn.system(string.format("doas -S %s", _cmd), password .. "\n")
  if vim.v.shell_error ~= 0 then
    print("\r\n")
    vim.notify(out, vim.log.levels.ERROR)
    return false
  end
  return true
end

vim.api.nvim_create_user_command("DoasWrite", function(opts)
  local tmpfile = vim.fn.tempname()
  local filepath
  if #opts.fargs == 1 then
    filepath = opts.fargs[1]
  else
    filepath = vim.fn.expand("%")
  end
  if not filepath or #filepath == 0 then
    vim.notify("E32: No file name", vim.log.levels.ERROR)
    return
  end
  -- `bs=1048576` is equivalent to `bs=1M` for GNU dd or `bs=1m` for BSD dd
  -- Both `bs=1M` and `bs=1m` are non-POSIX
  local _cmd = string.format(
    "dd if=%s of=%s bs=1048576",
    vim.fn.shellescape(tmpfile),
    vim.fn.shellescape(filepath)
  )
  -- no need to check error as this fails the entire function
  vim.api.nvim_exec2(string.format("write! %s", tmpfile), { output = true })
  if doas_exec(_cmd) then
    -- refreshes the buffer and prints the "written" message
    vim.cmd.checktime()
    -- exit command mode
    vim.api.nvim_feedkeys(
      vim.api.nvim_replace_termcodes("<Esc>", true, false, true),
      "n",
      true
    )
  end
  vim.fn.delete(tmpfile)
end, {
  nargs = "?",
  desc = "Write using doas permissions",
})
