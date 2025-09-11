return {
  {
    "nvim-telescope/telescope.nvim",
    branch = "master",
    keys = {
      {
        "<leader>sg",
        function()
          require("telescope.builtin").live_grep()
        end,
        desc = "[S]earch by [G]rep",
      },
      {
        "<leader>sw",
        function()
          require("telescope.builtin").grep_string()
        end,
        desc = "[S]earch current [W]ord",
      },
      {
        "<leader>sf",
        function()
          require("telescope.builtin").find_files()
        end,
        desc = "[S]earch [F]iles",
      },
      {
        "<leader><leader>",
        function()
          require("telescope.builtin").buffers()
        end,
        desc = "[ ] Find existing buffers",
      },
      {
        "<leader>/",
        function()
          require("telescope.builtin").current_buffer_fuzzy_find()
        end,
        desc = "[/] Fuzzily search in current buffer",
      },
      {
        "<leader>s/",
        function()
          require("telescope.builtin").live_grep({
            grep_open_files = true,
            prompt_title = "Live Grep in Open Files",
          })
        end,
        desc = "[S]earch [/] in Open Files",
      },
      {
        "<leader>st",
        function()
          require("telescope.builtin").treesitter()
        end,
        desc = "[S]earch [T]reesitter",
      },
      {
        "<leader>ss",
        function()
          require("telescope.builtin").builtin()
        end,
        desc = "[S]earch [S]elect Telescope",
      },
      {
        "<leader>sc",
        function()
          require("telescope.builtin").commands()
        end,
        desc = "[S]earch [C]ommands",
      },
      {
        "<leader>sh",
        function()
          require("telescope.builtin").help_tags()
        end,
        desc = "[S]earch [H]elp",
      },
      {
        "<leader>sm",
        function()
          require("telescope.builtin").man_pages()
        end,
        desc = "[S]earch [M]an pages",
      },
      {
        "<leader>sk",
        function()
          require("telescope.builtin").keymaps()
        end,
        desc = "[S]earch [K]eymaps",
      },
      {
        "<leader>sd",
        function()
          require("telescope.builtin").diagnostics()
        end,
        desc = "[S]earch [D]iagnostics",
      },
      -- {"<leader>sr", function() require("telescope.builtin").resume() end, desc = '[S]earch [R]esume' },
      {
        "<leader>s.",
        function()
          require("telescope.builtin").oldfiles()
        end,
        desc = '[S]earch Recent Files ("." for repeat)',
      },
      {
        "<leader>sq",
        function()
          require("telescope.builtin").quickfix()
        end,
        desc = "[S]earch [Q]uickfixlist",
      },
      {
        "<leader>sl",
        function()
          require("telescope.builtin").loclist()
        end,
        desc = "[S]earch [L]ocationlist",
      },
      {
        "<leader>sR",
        function()
          require("telescope.builtin").registers()
        end,
        desc = "[S]earch [R]egisters",
      },
      {
        "<leader>sa",
        function()
          require("telescope.builtin").autocommands()
        end,
        desc = "[S]earch [A]utocommands",
      },

      {
        "<leader>gc",
        function()
          require("telescope.builtin").git_bcommits()
        end,
        desc = "[G]it buffer [C]commits",
      },
      {
        "<leader>gc",
        function()
          require("telescope.builtin").git_bcommits_range()
        end,
        desc = "[G]it [C]commits for selected range",
      },
      {
        "<leader>gC",
        function()
          require("telescope.builtin").git_commits()
        end,
        desc = "[G]it (all) [C]commits",
      },
      {
        "<leader>gb",
        function()
          require("telescope.builtin").git_branches()
        end,
        desc = "[G]it [B]ranches",
      },
      {
        "<leader>gs",
        function()
          require("telescope.builtin").git_status()
        end,
        desc = "[G]it [S]tatus",
      },
      {
        "<leader>gS",
        function()
          require("telescope.builtin").git_stash()
        end,
        desc = "[G]it [S]tash",
      },
      {
        "<leader>sr",
        function()
          require("telescope").extensions.refactoring.refactors()
        end,
        mode = { "n", "x" },
        desc = "[S]earch [R]efactor",
      },
    },
    config = function()
      local actions = require("telescope.actions")
      local actions_layout = require("telescope.actions.layout")
      require("telescope").setup({
        defaults = {
          sorting_strategy = "ascending",
          layout_config = {
            prompt_position = "top",
            height = 0.95,
            width = 0.95,
            flip_columns = 200,
            vertical = { mirror = true },
          },
          layout_strategy = "flex",
          preview = {
            filesize_limit = 0.1, -- MB
          },
          scroll_strategy = "cycle",
          selection_strategy = "follow",
          color_devicons = false,
          mappings = {
            n = {
              ["<M-p>"] = actions_layout.toggle_preview,
              ["d"] = actions.delete_buffer + actions.move_to_top,
              ["a"] = actions.add_to_qflist,
              ["s"] = actions.select_all,
            },
            i = {
              ["jj"] = { "<esc>", type = "command" },
              ["<c-j>"] = actions.move_selection_next,
              ["<c-k>"] = actions.move_selection_previous,
              ["<C-u>"] = false,
              ["<M-p>"] = actions_layout.toggle_preview,
              ["<c-d>"] = actions.delete_buffer + actions.move_to_top,
            },
          },
        },
        pickers = {
          find_files = {
            follow = true,
            hidden = true,
            find_command = {
              "fd",
              "--type",
              "f",
              "--color",
              "never",
            },
          },
          live_grep = {
            additional_args = {
              "--hidden",
              "--fixed-strings",
            },
          },
          buffers = {
            initial_mode = "normal",
            sort_lastused = true,
          },
          current_buffer_fuzzy_find = {
            require("telescope.themes").get_dropdown({
              winblend = 10,
              previewer = false,
            }),
          },
          quickfix = {
            initial_mode = "normal",
          },
          loclist = {
            initial_mode = "normal",
          },
          registers = {
            initial_mode = "normal",
          },
          lsp_definitions = {
            initial_mode = "normal",
          },
          lsp_type_definitions = {
            initial_mode = "normal",
          },
          lsp_implementations = {
            initial_mode = "normal",
          },
          lsp_references = {
            initial_mode = "normal",
          },
          lsp_incoming_calls = {
            initial_mode = "normal",
          },
          lsp_outgoing_calls = {
            initial_mode = "normal",
          },
        },
        extensions = {
          fzf = {
            fuzzy = true, -- false will only do exact matching
            override_generic_sorter = true, -- override the generic sorter
            override_file_sorter = true, -- override the file sorter
            case_mode = "smart_case", -- or "ignore_case" or "respect_case"
          },
        },
      })
      require("telescope").load_extension("fzf")
      require("telescope").load_extension("ui-select")
      require("telescope").load_extension("refactoring")

      vim.api.nvim_create_autocmd("LspAttach", {
        callback = function(event)
          local b = require("telescope.builtin")
          local bnmap = function(keys, func, desc)
            vim.keymap.set("n", keys, func, { buffer = event.buf, desc = "LSP: " .. desc })
          end
          bnmap("gd", b.lsp_definitions, "[G]oto [D]efinition")
          bnmap("gvd", function()
            b.lsp_definitions({ jump_type = "vsplit" })
          end, "[G]oto in a [V]ertical split to [D]efinition")
          bnmap("gxd", function()
            b.lsp_definitions({ jump_type = "split" })
          end, "[G]oto in a [X]horizontal split to [D]efinition")
          bnmap("gtd", function()
            b.lsp_definitions({ jump_type = "tab" })
          end, "[G]oto in a [T]ab to [D]efinition")
          bnmap("<leader>D", b.lsp_type_definitions, "Type [D]efinition")
          bnmap("<leader>vD", function()
            b.lsp_type_definitions({ jump_type = "vsplit" })
          end, "Open in a [V]ertical split Type [D]efinition")
          bnmap("<leader>xD", function()
            b.lsp_type_definitions({ jump_type = "split" })
          end, "Open in a [X]horizontal split Type [D]efinition")
          bnmap("<leader>tD", function()
            b.lsp_type_definitions({ jump_type = "tab" })
          end, "Open in a [T]ab Type [D]efinition")
          bnmap("gri", b.lsp_implementations, "[G]oto [I]mplementation")
          bnmap("grvi", function()
            b.lsp_implementations({ jump_type = "vsplit" })
          end, "[G]oto in a [V]ertical split to [I]mplementation")
          bnmap("grxi", function()
            b.lsp_implementations({ jump_type = "split" })
          end, "[G]oto in a [X]horizontal split to [I]mplementation")
          bnmap("grti", function()
            b.lsp_implementations({ jump_type = "tab" })
          end, "[G]oto in a [T]ab to [I]mplementation")
          bnmap("grr", b.lsp_references, "[G]oto [R]eferences")
          bnmap("<leader>ic", b.lsp_incoming_calls, "[I]ncoming [C]alls")
          bnmap("<leader>oc", b.lsp_outgoing_calls, "[O]utgoing [C]alls")
          bnmap("gO", b.lsp_document_symbols, "d[O]ocument symbols")
          bnmap(
            "<leader>ws",
            b.lsp_dynamic_workspace_symbols,
            "[W]orkspace [S]ymbols"
          )
        end,
      })
    end,
    dependencies = {
      "nvim-lua/plenary.nvim",
      {
        "nvim-telescope/telescope-fzf-native.nvim",
        build = "make",
      },
      "nvim-telescope/telescope-ui-select.nvim",
      "ThePrimeagen/refactoring.nvim",
    },
  },
}
