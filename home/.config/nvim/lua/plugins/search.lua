local fzflua = require("fzf-lua")
fzflua.setup({
  keymap = {
    builtin = {
      true,
      ["<M-p>"] = "toggle-preview",
    },
  },
  grep = {
    hidden = true,
    RIPGREP_CONFIG_PATH = "~/.config/ripgrep/ripgreprc",
  },
  lsp = {
    includeDeclaration = false,
  },
  actions = {
    files = {
      true,
      ["ctrl-x"] = fzflua.actions.file_split,
    },
  },
})
fzflua.register_ui_select()

vim.keymap.set("n", "<localleader>b", function()
  fzflua.buffers()
end, { desc = "fzf-lua [B]uffers" })
vim.keymap.set("n", "<localleader>/", function()
  fzflua.live_grep()
end, { desc = "fzf-lua live grep" })
vim.keymap.set("n", "<localleader>f", function()
  fzflua.files()
end, { desc = "fzf-lua [F]iles" })
vim.keymap.set("n", "<leader><leader>", function()
  fzflua.global()
end, { desc = "fzf-lua global picker" })
vim.keymap.set("n", "<localleader>d", function()
  fzflua.diagnostics()
end, { desc = "fzf-lua [D]iagnostics" })
vim.keymap.set("n", "<localleader>r", function()
  fzflua.resume()
end, { desc = "fzf-lua [R]esume" })
vim.keymap.set("n", "<localleader>gc", function()
  fzflua.git_bcommits()
end, { desc = "[G]it buffer [C]commits" })
vim.keymap.set("v", "<localleader>gc", function()
  fzflua.git_bcommits_range()
end, { desc = "[G]it [C]commits for selected range" })
vim.keymap.set("n", "<localleader>gC", function()
  fzflua.git_commits()
end, { desc = "[G]it (all) [C]commits" })
vim.keymap.set("n", "<localleader>gb", function()
  fzflua.git_branches()
end, { desc = "[G]it [B]ranches" })
vim.keymap.set("n", "<localleader>gs", function()
  fzflua.git_status()
end, { desc = "[G]it [S]tatus" })
vim.keymap.set("n", "<localleader>gS", function()
  fzflua.git_stash()
end, { desc = "[G]it [S]tash" })
