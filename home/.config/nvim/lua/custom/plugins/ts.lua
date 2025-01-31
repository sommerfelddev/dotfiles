return {
  {
    'nvim-treesitter/nvim-treesitter',
    dependencies = {
      'nvim-treesitter/nvim-treesitter-textobjects',
      "nvim-treesitter/nvim-treesitter-refactor",
      "theHamsta/crazy-node-movement",
      "theHamsta/nvim-treesitter-pairs",
      "RRethy/nvim-treesitter-endwise",
    },
    build = ":TSUpdate",
    config = function()
      require("nvim-treesitter.configs").setup({
        ensure_installed = {
          "bash",
          "c",
          "cmake",
          "comment",
          "cpp",
          "css",
          "diff",
          "dockerfile",
          "doxygen",
          "fortran",
          "git_config",
          "git_rebase",
          "gitattributes",
          "gitcommit",
          "gitignore",
          "gpg",
          "html",
          "http",
          "ini",
          "javascript",
          "jsdoc",
          "json",
          "jsonc",
          "llvm",
          "lua",
          "luadoc",
          "luap",
          "make",
          "markdown",
          "markdown_inline",
          "python",
          "regex",
          "rust",
          "sql",
          "tablegen",
          "todotxt",
          "toml",
          "typescript",
          "vim",
          "vimdoc",
          "xml",
          "yaml",
        },
        highlight = {
          enable = true,
          additional_vim_regex_highlighting = false,
        },
        incremental_selection = {
          enable = true,
          keymaps = {
            init_selection = "gnn",
            node_incremental = "grn",
            scope_incremental = "grc",
            node_decremental = "grm",
          },
        },
        indent = { enable = true },
        refactor = {
          highlight_definitions = { enable = true },
          highlight_current_scope = { enable = true },
        },
        textobjects = {
          select = {
            enable = true,
            -- Automatically jump forward to textobj, similar to targets.vim
            lookahead = true,
            keymaps = {
              -- You can use the capture groups defined in textobjects.scm
              ["af"] = "@function.outer",
              ["if"] = "@function.inner",
              ["ac"] = "@class.outer",
              ["ic"] = "@class.inner",
            },
          },
          swap = {
            enable = true,
            swap_next = { ["<leader>a"] = "@parameter.inner" },
            swap_previous = { ["<leader>A"] = "@parameter.inner" },
          },
          move = {
            enable = true,
            set_jumps = true, -- whether to set jumps in the jumplist
            goto_next_start = {
              ["]m"] = "@function.outer",
              ["]]"] = "@class.outer",
            },
            goto_next_end = {
              ["]M"] = "@function.outer",
              ["]["] = "@class.outer",
            },
            goto_previous_start = {
              ["[m"] = "@function.outer",
              ["[["] = "@class.outer",
            },
            goto_previous_end = {
              ["[M"] = "@function.outer",
              ["[]"] = "@class.outer",
            },
          },
          lsp_interop = {
            enable = true,
            peek_definition_code = {
              ["df"] = "@function.outer",
              ["dF"] = "@class.outer",
            },
          },
        },
        matchup = {
          enable = true,
        },
        pairs = {
          enable = true,
          goto_right_end = false,
          keymaps = { goto_partner = "%" },
        },
        node_movement = {
          enable = true,
          keymaps = {
            move_up = "<a-k>",
            move_down = "<a-j>",
            move_left = "<a-h>",
            move_right = "<a-l>",
            swap_left = "<s-a-h>", -- will only swap when one of "swappable_textobjects" is selected
            swap_right = "<s-a-l>",
            select_current_node = "<leader><Cr>",
          },
          swappable_textobjects = { '@function.outer', '@parameter.inner', '@statement.outer' },
          allow_switch_parents = true, -- more craziness by switching parents while staying on the same level, false prevents you from accidentally jumping out of a function
          allow_next_parent = true, -- more craziness by going up one level if next node does not have children
        },
        tree_docs = {
          enable = true,
        },
        endwise = {
          enable = true,
        },
      })
    end
  },
  "nvim-treesitter/nvim-treesitter-context",
}
