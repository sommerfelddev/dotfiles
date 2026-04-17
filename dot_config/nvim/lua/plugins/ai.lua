require("copilot").setup({
  suggestion = { enabled = false },
  panel = { enabled = false },
  server_opts_overrides = {
    settings = {
      telemetry = {
        telemetryLevel = "off",
      },
    },
  },
  nes = {
    enabled = true,
    keymap = {
      accept_and_goto = "<leader>p",
      accept = false,
      dismiss = "<Esc>",
    },
  },
})

-- Accept NES in insert mode (copilot.lua only binds normal mode)
vim.keymap.set("i", "<C-f>", function()
  local ok, nes = pcall(require, "copilot-lsp.nes")
  if ok and nes.apply_pending_nes() then
    return
  end
  -- Fallback: native <C-f> (scroll window forward)
  local key = vim.api.nvim_replace_termcodes("<C-f>", true, false, true)
  vim.api.nvim_feedkeys(key, "n", false)
end, { desc = "Accept Copilot NES / scroll forward" })

vim.keymap.set("n", "<leader>tc", function()
  require("copilot.command").toggle()
end, { desc = "[T]oggle [C]opilot attachment" })
