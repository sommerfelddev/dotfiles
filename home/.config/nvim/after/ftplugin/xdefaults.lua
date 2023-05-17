vim.bo.commentstring = "! %s"
vim.api.nvim_create_augroup("xdefaults", {})
vim.api.nvim_create_autocmd(
  "BufWritePost",
  { group = "xdefaults", buffer = 0, command = "!xrdb %" }
)

vim.b.undo_ftplugin = vim.b.undo_ftplugin
  .. "| setlocal commentstring<
