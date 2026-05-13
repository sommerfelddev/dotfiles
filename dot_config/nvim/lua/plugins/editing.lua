require("guess-indent").setup({})

require("various-textobjs").setup({
  keymaps = {
    useDefaults = true,
  },
})

-- dial.nvim: enhanced increment/decrement on standard vim keys
vim.keymap.set("n", "<C-a>", function()
  return require("dial.map").inc_normal()
end, { expr = true, desc = "Increment" })
vim.keymap.set("n", "<C-x>", function()
  return require("dial.map").dec_normal()
end, { expr = true, desc = "Decrement" })
vim.keymap.set("v", "<C-a>", function()
  return require("dial.map").inc_visual()
end, { expr = true, desc = "Increment" })
vim.keymap.set("v", "<C-x>", function()
  return require("dial.map").dec_visual()
end, { expr = true, desc = "Decrement" })
vim.keymap.set("v", "g<C-a>", function()
  return require("dial.map").inc_gvisual()
end, { expr = true, desc = "Increment (sequential)" })
vim.keymap.set("v", "g<C-x>", function()
  return require("dial.map").dec_gvisual()
end, { expr = true, desc = "Decrement (sequential)" })
