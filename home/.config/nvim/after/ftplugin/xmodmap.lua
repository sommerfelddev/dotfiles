vim.api.nvim_create_autocmd(
  "BufWritePost",
  { buffer = 0, command = "!xmodmap %" }
)
