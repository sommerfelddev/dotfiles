vim.bo.commentstring = "! %s"

vim.api.nvim_create_autocmd(
  "BufWritePost",
  {
    group = vim.api.nvim_create_augroup("xdefaults", { clear = true }),
    buffer = 0,
    command = "!xrdb %",
  }
)
