vim.wo.spell = true
vim.b.undo_ftplugin = vim.b.undo_ftplugin .. "|setlocal spell<"
vim.cmd([[match ErrorMsg /\%1l.\%>50v/]])
local bufnr = vim.api.nvim_buf_get_number(0)
require("mapper").ncmd("gd", "DiffGitCached", nil, bufnr)
