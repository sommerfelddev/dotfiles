vim.wo.spell = true
vim.b.undo_ftplugin = vim.b.undo_ftplugin .. "|setlocal spell<"
vim.cmd([[match ErrorMsg /\%1l.\%>50v/]])
