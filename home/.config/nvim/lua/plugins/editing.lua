return {
  {
    "nmac427/guess-indent.nvim",
    event = "BufRead",
    opts = {},
  },
  {
    "kylechui/nvim-surround",
    event = "VeryLazy",
    opts = {},
  },
  {
    "chrisgrieser/nvim-various-textobjs",
    event = "VeryLazy",
    opts = {
      keymaps = {
        useDefaults = true,
      },
    },
  },
  {
    "monaqa/dial.nvim",
    keys = {
      {
        "]i",
        function()
          require("dial.map").inc_normal()
        end,
        expr = true,
        desc = "Increment",
      },
      {
        "[i",
        function()
          require("dial.map").dec_normal()
        end,
        expr = true,
        desc = "Decrement",
      },
      {
        "]i",
        function()
          require("dial.map").inc_visual()
        end,
        expr = true,
        mode = "v",
        desc = "Increment",
      },
      {
        "[i",
        function()
          require("dial.map").dec_visual()
        end,
        expr = true,
        mode = "v",
        desc = "Decrement",
      },
    },
  },
  {
    "ThePrimeagen/refactoring.nvim",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-treesitter/nvim-treesitter",
    },
    keys = {
      {
        "<leader>re",
        function()
          require("refactoring").refactor("Extract Function")
        end,
        mode = "x",
        desc = "[R]efactor [E]xtract function",
      },
      {
        "<leader>rf",
        function()
          require("refactoring").refactor("Extract Function To File")
        end,
        mode = "x",
        desc = "[R]efactor extract function to [F]ile",
      },
      {
        "<leader>rv",
        function()
          require("refactoring").refactor("Extract Variable")
        end,
        mode = "x",
        desc = "[R]efactor extract [V]ariable",
      },
      {
        "<leader>rI",
        function()
          require("refactoring").refactor("Inline Function")
        end,
        desc = "[R]efactor [I]nline function",
      },
      {
        "<leader>ri",
        function()
          require("refactoring").refactor("Inline Variable")
        end,
        mode = { "x", "n" },
        desc = "[R]efactor [I]nline variable",
      },
      {
        "<leader>rb",
        function()
          require("refactoring").refactor("Extract Block")
        end,
        desc = "[R]efactor extract [B]lock",
      },
      {
        "<leader>rB",
        function()
          require("refactoring").refactor("Extract Block To File")
        end,
        desc = "[R]efactor extract [B]lock to file",
      },
      {
        "<leader>rp",
        function()
          require("refactoring").debug.printf({})
        end,
        desc = "[R]efactor [P]rint",
      },

      {
        "<leader>rV",
        function()
          require("refactoring").debug.print_var({})
        end,
        mode = { "x", "n" },
        desc = "[R]efactor [P]rint [V]ariable",
      },
      {
        "<leader>rc",
        function()
          require("refactoring").debug.cleanup({})
        end,
        desc = "[R]efactor [C]leanup",
      },
    },
    opts = {},
  },
}
