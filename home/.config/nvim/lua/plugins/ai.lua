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

vim.keymap.set("n", "<leader>tc", function()
  require("copilot.command").toggle()
end, { desc = "[T]oggle [C]opilot attachment" })
