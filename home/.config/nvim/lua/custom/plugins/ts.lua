return {
  {
    "aaronik/treewalker.nvim",
    keys = {
      {
        "<a-k>",
        "<cmd>Treewalker Up<cr>",
        { "n", "v" },
        silent = true,
        desc = "Moves up to the previous neighbor node",
      },
      {
        "<a-j>",
        "<cmd>Treewalker Down<cr>",
        { "n", "v" },
        silent = true,
        desc = "Moves up to the next neighbor node",
      },
      {
        "<a-h>",
        "<cmd>Treewalker Left<cr>",
        { "n", "v" },
        silent = true,
        desc = "Moves to the first ancestor node that's on a different line from the current node",
      },
      {
        "<a-l>",
        "<cmd>Treewalker Right<cr>",
        { "n", "v" },
        silent = true,
        desc = "Moves to the next node down that's indented further than the current node",
      },
      {
        "<s-a-k>",
        "<cmd>Treewalker SwapUp<cr>",
        silent = true,
        desc = "Swaps the highest node on the line upwards in the document",
      },
      {
        "<s-a-j>",
        "<cmd>Treewalker SwapDown<cr>",
        silent = true,
        desc = "Swaps the biggest node on the line downward in the document",
      },
      {
        "<s-a-h>",
        "<cmd>Treewalker SwapLeft<cr>",
        silent = true,
        desc = "Swap the node under the cursor with its previous neighbor",
      },
      {
        "<s-a-l>",
        "<cmd>Treewalker SwapRight<cr>",
        silent = true,
        desc = "Swap the node under the cursor with its next neighbor",
      },
    },
    opts = {},
  },
  {
    "nvim-treesitter/nvim-treesitter",
    branch = "main",
    lazy = false,
    dependencies = {
      -- "theHamsta/nvim-treesitter-pairs", -- Reneable once main branch is supported
      {
        "LiadOz/nvim-dap-repl-highlights",
        opts = {},
      },
    },
    build = ":TSUpdate",
    config = function()
      require("nvim-treesitter").install({
        "awk",
        "bash",
        "c",
        "cmake",
        "comment",
        "cpp",
        "css",
        "csv",
        "diff",
        "dockerfile",
        "dap_repl",
        "doxygen",
        "editorconfig",
        "fortran",
        "git_config",
        "git_rebase",
        "gitattributes",
        "gitcommit",
        "gitignore",
        "groovy",
        "gpg",
        "hlsplaylist",
        "html",
        "http",
        "ini",
        "javascript",
        "jq",
        "jsdoc",
        "json",
        "just",
        "llvm",
        "lua",
        "luadoc",
        "luap",
        "make",
        "markdown",
        "markdown_inline",
        "query",
        "passwd",
        "printf",
        "python",
        "regex",
        "readline",
        "requirements",
        "rust",
        "sql",
        "ssh_config",
        "strace",
        "sxhkdrc",
        "tablegen",
        "tmux",
        "todotxt",
        "toml",
        "typescript",
        "vim",
        "vimdoc",
        "xcompose",
        "xml",
        "xresources",
        "yaml",
      })
    end,
  },
  "RRethy/nvim-treesitter-endwise",
  { "nvim-treesitter/nvim-treesitter-context", opts = {} },
  {
    "JoosepAlviste/nvim-ts-context-commentstring",
    config = function()
      require("ts_context_commentstring").setup({
        enable_autocmd = false,
      })
      local get_option = vim.filetype.get_option

      vim.filetype.get_option = function(filetype, option)
        return option == "commentstring"
            and require("ts_context_commentstring.internal").calculate_commentstring()
          or get_option(filetype, option)
      end
    end,
  },
}
