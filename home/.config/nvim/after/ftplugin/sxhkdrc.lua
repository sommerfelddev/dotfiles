vim.bo.commentstring = "# %s"

vim.api.nvim_create_autocmd(
  "BufWritePost",
  {
    group = vim.api.nvim_create_augroup("sxhkd", { clear = true }),
    buffer = 0,
    command = "!pkill --signal SIGUSR1 sxhkd",
  }
)
