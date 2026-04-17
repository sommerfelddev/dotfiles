-- Seamless navigation between neovim splits and zellij panes
require("smart-splits").setup({})
vim.keymap.set("n", "<C-h>", require("smart-splits").move_cursor_left, { desc = "Move to left split/pane" })
vim.keymap.set("n", "<C-j>", require("smart-splits").move_cursor_down, { desc = "Move to below split/pane" })
vim.keymap.set("n", "<C-k>", require("smart-splits").move_cursor_up, { desc = "Move to above split/pane" })
vim.keymap.set("n", "<C-l>", require("smart-splits").move_cursor_right, { desc = "Move to right split/pane" })

require("which-key").setup({
  spec = {
    { "g", group = "[G]oto" },
    { "yo", group = "Toggle options" },
    { "]", group = "Navigate to next" },
    { "[", group = "Navigate to previous" },
    { "<leader>c", group = "[C]ode", mode = { "n", "x" } },
    { "<leader>d", group = "[D]ocument" },
    { "<leader>g", group = "[G]it" },
    { "<leader>h", group = "Git [H]unk", mode = { "n", "v" } },
    { "<leader>o", group = "[O]verseer" },
    { "<leader>r", group = "[R]efactor" },
    { "<leader>s", group = "[S]earch" },
    { "<leader>w", group = "[W]orkspace" },
    { "<leader>t", group = "[T]oggle" },
  },
})

vim.keymap.set("n", "<leader>?", function()
  require("which-key").show({ global = false })
end, { desc = "Buffer Local Keymaps (which-key)" })

require("quicker").setup({
  keys = {
    {
      ">",
      function()
        require("quicker").expand({
          before = 2,
          after = 2,
          add_to_existing = true,
        })
      end,
      desc = "Expand quickfix context",
    },
    {
      "<",
      function()
        require("quicker").collapse()
      end,
      desc = "Collapse quickfix context",
    },
  },
})

vim.keymap.set("n", "<leader>tq", function()
  require("quicker").toggle()
end, { desc = "[T]oggle [Q]uickfix" })
vim.keymap.set("n", "<leader>tl", function()
  require("quicker").toggle({ loclist = true })
end, { desc = "[T]oggle [L]oclist" })

require("oil").setup({})
