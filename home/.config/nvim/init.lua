require("config.options")

_G.P = function(v)
  print(vim.inspect(v))
  return v
end

-- Pre-load globals (must be set before plugins load)
vim.g.copilot_nes_debounce = 500

-- Build hooks for plugins that need post-install steps
vim.api.nvim_create_autocmd("User", {
  pattern = "PackChanged",
  callback = function(ev)
    if ev.data.kind ~= "install" and ev.data.kind ~= "update" then
      return
    end
    if ev.data.spec.name == "markdown-preview.nvim" then
      vim.system({ "yarn", "install" }, { cwd = ev.data.path .. "/app" })
    end
  end,
})

local gh = function(x)
  return "https://github.com/" .. x
end

vim.pack.add({
  -- UI
  gh("ellisonleao/gruvbox.nvim"),
  gh("saghen/blink.indent"),
  gh("nvim-lualine/lualine.nvim"),
  gh("AndreM222/copilot-lualine"),

  -- Treesitter
  { src = gh("nvim-treesitter/nvim-treesitter"), version = "main" },
  gh("RRethy/nvim-treesitter-endwise"),
  gh("nvim-treesitter/nvim-treesitter-context"),
  gh("JoosepAlviste/nvim-ts-context-commentstring"),
  gh("aaronik/treewalker.nvim"),
  gh("LiadOz/nvim-dap-repl-highlights"),

  -- Completion
  gh("saghen/blink.compat"),
  { src = gh("saghen/blink.cmp"), version = vim.version.range("*") },
  gh("rafamadriz/friendly-snippets"),
  gh("fang2hou/blink-copilot"),
  gh("rcarriga/cmp-dap"),
  gh("xzbdmw/colorful-menu.nvim"),
  { src = gh("saghen/blink.pairs"), version = vim.version.range("*") },
  { src = gh("saghen/blink.download"), version = "main" },

  -- Editing
  gh("nmac427/guess-indent.nvim"),
  gh("kylechui/nvim-surround"),
  gh("chrisgrieser/nvim-various-textobjs"),
  gh("monaqa/dial.nvim"),
  gh("ThePrimeagen/refactoring.nvim"),
  gh("nvim-lua/plenary.nvim"),

  -- Git
  gh("akinsho/git-conflict.nvim"),
  gh("NeogitOrg/neogit"),
  gh("ruifm/gitlinker.nvim"),
  gh("lewis6991/gitsigns.nvim"),

  -- LSP
  gh("folke/lazydev.nvim"),
  gh("neovim/nvim-lspconfig"),
  gh("j-hui/fidget.nvim"),
  gh("williamboman/mason.nvim"),
  gh("williamboman/mason-lspconfig.nvim"),
  gh("WhoIsSethDaniel/mason-tool-installer.nvim"),
  gh("stevearc/conform.nvim"),
  gh("mrcjkb/rustaceanvim"),
  gh("mfussenegger/nvim-lint"),
  gh("rachartier/tiny-inline-diagnostic.nvim"),

  -- Debug
  { src = gh("miroshQa/debugmaster.nvim"), version = "dashboard" },
  gh("mfussenegger/nvim-dap"),
  gh("theHamsta/nvim-dap-virtual-text"),
  gh("jay-babu/mason-nvim-dap.nvim"),

  -- Runner
  gh("stevearc/overseer.nvim"),

  -- Search
  { src = gh("ibhagwan/fzf-lua"), version = "main" },

  -- Session
  gh("rmagatti/auto-session"),

  -- AI
  gh("zbirenbaum/copilot.lua"),
  gh("copilotlsp-nvim/copilot-lsp"),

  -- Misc
  gh("iamcco/markdown-preview.nvim"),
  gh("aserowy/tmux.nvim"),
  gh("folke/which-key.nvim"),
  gh("stevearc/quicker.nvim"),
  gh("stevearc/oil.nvim"),
}, { confirm = false })

-- Colorscheme (must be set immediately after plugins are on rtp)
require("gruvbox").setup({})
vim.o.background = "dark"
vim.cmd.colorscheme("gruvbox")

-- Plugin configurations (order matters for dependencies)
require("plugins.ui")
require("plugins.treesitter")
require("plugins.completion")
require("plugins.editing")
require("plugins.git")
require("plugins.lsp")
require("plugins.debug")
require("plugins.runner")
require("plugins.search")
require("plugins.session")
require("plugins.ai")
require("plugins.init")

require("config.keymaps")
require("config.autocmds")
