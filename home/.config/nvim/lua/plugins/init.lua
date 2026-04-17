return {
  { "nvim-lua/plenary.nvim", branch = "master", lazy = true },
  {
    "iamcco/markdown-preview.nvim",
    cmd = { "MarkdownPreviewToggle", "MarkdownPreview", "MarkdownPreviewStop" },
    build = "cd app && yarn install",
    ft = "markdown",
  },
  {
    "aserowy/tmux.nvim",
    event = "VeryLazy",
    opts = {
      resize = {
        enable_default_keybindings = false,
      },
    },
  },
  {
    "folke/which-key.nvim",
    event = "VeryLazy",
    opts = {
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
    },
    keys = {
      {
        "<leader>?",
        function()
          require("which-key").show({ global = false })
        end,
        desc = "Buffer Local Keymaps (which-key)",
      },
    },
  },
  {
    "stevearc/quicker.nvim",
    event = "FileType qf",
    keys = {
      {
        "<leader>tq",
        function()
          require("quicker").toggle()
        end,
        desc = "[T]oggle [Q]uickfix",
      },
      {
        "<leader>tl",
        function()
          require("quicker").toggle({ loclist = true })
        end,
        desc = "[T]oggle [L]oclist",
      },
    },
    opts = {
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
    },
  },
  {
    "stevearc/oil.nvim",
    opts = {},
    lazy = false,
  },
}
