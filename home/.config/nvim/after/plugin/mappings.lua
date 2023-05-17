local map = require("mapper")

map.n("<Space>", "<Nop>")

-- make an accidental ; press also enter command mode
-- temporarily disabled to to vim-sneak plugin
map.n(";", ":")

-- highlight last inserted text
map.n("gV", "`[v`]")

map.n("<down>", "<c-e>")
map.n("<up>", "<c-y>")

-- go to first non-blank character of current line
map.n("<c-a>", "^")
map.v("<c-a>", "^")
map.n("<c-e>", "$")
map.v("<c-e>", "$")

-- This extends p in visual mode (note the noremap), so that if you paste from
-- the unnamed (ie. default) register, that register content is not replaced by
-- the visual selection you just pasted over–which is the default behavior.
-- This enables the user to yank some text and paste it over several places in
-- a row, without using a named register
-- map.v('p', "p:if v:register == '"'<Bar>let @@=@0<Bar>endif<cr>")
map.v("p", 'p:let @+=@0<CR>:let @"=@0<CR>')

map.v("<leader>p", '"_dP')
map.n("<leader>d", '"_d')
map.n("<leader>D", '"_D')
map.map("", "<leader>c", '"_c')
map.map("", "<leader>C", '"_C')

-- Find and Replace binds
map.ncmdi("<leader>s", "%s/")
map.vcmdi("<leader>s", "s/")
map.ncmdi("<leader>gs", '%s/<c-r>"/')
map.vcmdi("<leader>gs", 's/<c-r>"/')
map.ncmdi("<Leader>S", "%s/<C-r><C-w>/")

map.ncmd("<leader>x", "wall")
map.ncmd("<leader>z", "wqall")
map.ncmd("<leader>q", "quitall")
map.ncmd("<localleader>x", "update")

map.t("<Esc>", "<c-\\><c-n>", { silent = true, noremap = true, expr = true })

map.n("gw", vim.diagnostic.open_float)
map.n("gW", vim.diagnostic.setloclist)
map.n("[w", vim.diagnostic.goto_prev)
map.n("]w", vim.diagnostic.goto_next)
map.n("[e", function()
  vim.diagnostic.goto_prev({ severity = vim.diagnostic.severity.ERROR })
end)
map.n("]e", function()
  vim.diagnostic.goto_next({ severity = vim.diagnostic.severity.ERROR })
end)
