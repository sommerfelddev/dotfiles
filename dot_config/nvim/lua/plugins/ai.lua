-- Prefer the chezmoi-pinned Node 24 (host has Arch's system node 26, which
-- breaks copilot-language-server — see
-- ~/.local/share/chezmoi/run_onchange_after_install-copilot-node.sh). Fall
-- back to `node` on PATH for hosts that don't run chezmoi (remote-dev VM
-- via Nix Home-Manager, where home.nix pins nodejs_24 in the profile).
local pinned_node = vim.fs.joinpath(
  vim.env.XDG_DATA_HOME or (vim.env.HOME .. "/.local/share"),
  "copilot-node/bin/node"
)
local copilot_node = vim.fn.executable(pinned_node) == 1 and pinned_node
  or "node"

require("copilot").setup({
  suggestion = { enabled = false },
  panel = { enabled = false },
  copilot_node_command = copilot_node,
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
