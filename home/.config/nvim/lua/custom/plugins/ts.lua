return {
  {
    'nvim-treesitter/nvim-treesitter',
    dependencies = {
      'nvim-treesitter/nvim-treesitter-textobjects',
      "nvim-treesitter/nvim-treesitter-refactor",
      "RRethy/nvim-treesitter-textsubjects",
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
          "cuda",
          "diff",
          "dockerfile",
          "fortran",
          "git_rebase",
          "gitattributes",
          "gitcommit",
          "gitignore",
          "go",
          "html",
          "javascript",
          "jsdoc",
          "json",
          "llvm",
          "lua",
          "make",
          "markdown",
          "markdown_inline",
          "ninja",
          "python",
          "regex",
          "rust",
          "sql",
          "todotxt",
          "toml",
          "typescript",
          "vim",
          "vimdoc",
          "yaml"
        },
        -- ignore_install = { "phpdoc" },
        highlight = {
          enable = true, -- false will disable the whole extension
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
          smart_rename = { enable = true, keymaps = { smart_rename = "grr" } },
          navigation = {
            enable = true,
            keymaps = {
              goto_definition = "gnd",
              list_definitions = "gnD",
              list_definitions_toc = "gO",
              goto_next_usage = "<a-*>",
              goto_previous_usage = "<a-#>",
            },
          },
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
        textsubjects = {
          enable = true,
          keymaps = { ["."] = "textsubjects-smart", [";"] = "textsubjects-big" },
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
}
