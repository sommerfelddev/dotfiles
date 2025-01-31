local map = require("mapper")

return {
  { "nvim-lua/plenary.nvim", lazy = true },
  { "tpope/vim-repeat",      event = "VeryLazy" },
  'tpope/vim-sleuth',
  {
    'tummetott/unimpaired.nvim',
    keys = { "]", "[", "yo" },
    opts = {
      -- add options here if you wish to override the default settings
    },
  },
  { "kylechui/nvim-surround", config = true },
  {
    "Julian/vim-textobj-variable-segment",
    dependencies = { "kana/vim-textobj-user" },
  },
  {
    "monaqa/dial.nvim",
    config = function()
      map.n("]i", require("dial.map").inc_normal())
      map.n("[i", require("dial.map").dec_normal())
      map.v("]i", require("dial.map").inc_visual())
      map.v("[i", require("dial.map").dec_visual())
    end
  },
  {
    "iamcco/markdown-preview.nvim",
    cmd = { "MarkdownPreviewToggle", "MarkdownPreview", "MarkdownPreviewStop" },
    build = "cd app && yarn install",
    ft = { "markdown" },
  },
  {
    "kwkarlwang/bufresize.nvim",
    config = true
  },
}
