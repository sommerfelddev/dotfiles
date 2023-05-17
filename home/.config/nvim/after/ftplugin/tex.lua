vim.wo.spell = true
vim.bo.formatoptions = vim.bo.formatoptions .. "t"
vim.b.undo_ftplugin = vim.b.undo_ftplugin
  .. "|setlocal spell< |setlocal formatoptions<"
