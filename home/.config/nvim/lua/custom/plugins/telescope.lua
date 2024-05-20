local map = require("mapper")

return {
  {
    "nvim-telescope/telescope.nvim",
    config = function()
      local actions = require("telescope.actions")
      require("telescope").setup({
        defaults = {
          sorting_strategy = "ascending",
          layout_config = {
            prompt_position = "top",
          },
          scroll_strategy = "cycle",
          selection_strategy = "follow",
          color_devicons = false,
          mappings = {
            i = {
              ["<c-j>"] = actions.move_selection_next,
              ["<c-k>"] = actions.move_selection_previous,
            },
          },
          extensions = {
            fzf = {
              fuzzy = true,                   -- false will only do exact matching
              override_generic_sorter = true, -- override the generic sorter
              override_file_sorter = true,    -- override the file sorter
              case_mode = "smart_case",       -- or "ignore_case" or "respect_case"
            },
            ["ui-select"] = {
              require("telescope.themes").get_dropdown({
                -- even more opts
              }),
            },
          },
        },
      })
      require("telescope").load_extension("fzf")
      require("telescope").load_extension("ui-select")

      local b = require("telescope.builtin")

      map.n("<localleader>B", b.builtin)
      map.n("<localleader>/", b.live_grep)
      map.n("<localleader>?", b.grep_string)
      map.n("<localleader>f", function()
        b.find_files({
          find_command = {
            "fd",
            "--type",
            "file",
            "--follow",
            "--hidden",
            "--exclude",
            ".git",
          },
        })
      end)
      map.n("<localleader>b", function()
        b.buffers({ sort_lastused = true, initial_mode = "normal" })
      end)

      map.n("<localleader>t", b.treesitter)

      map.n("<localleader>c", b.commands)
      map.n("<localleader>h", b.help_tags)
      map.n("<localleader>m", b.man_pages)
      map.n("<localleader>k", b.keymaps)
      map.n("<localleader>Q", function()
        b.quickfix({ initial_mode = "normal" })
      end)
      map.n("<localleader>L", function()
        b.loclist({ initial_mode = "normal" })
      end)
      map.n("<localleader>R", function()
        b.registers({ initial_mode = "normal" })
      end)
      map.n("<localleader>A", b.autocommands)


      vim.api.nvim_create_autocmd("LspAttach", {
        callback = function(event)
          local bnmap = function(keys, func)
            map.n(keys, func, { buffer = event.buf })
          end
          bnmap("gd", function()
            b.lsp_definitions({ initial_mode = "normal" })
          end)
          bnmap("gvd", function()
            b.lsp_definitions({ initial_mode = "normal", jump_type = "vsplit" })
          end)
          bnmap("gxd", function()
            b.lsp_definitions({ initial_mode = "normal", jump_type = "split" })
          end)
          bnmap("gtd", function()
            b.lsp_definitions({ initial_mode = "normal", jump_type = "tab" })
          end)
          bnmap("gi", function()
            b.lsp_implementations({ initial_mode = "normal" })
          end)
          bnmap("gvi", function()
            b.lsp_implementations({ initial_mode = "normal", jump_type = "vsplit" })
          end)
          bnmap("gxi", function()
            b.lsp_implementations({ initial_mode = "normal", jump_type = "split" })
          end)
          bnmap("gti", function()
            b.lsp_implementations({ initial_mode = "normal", jump_type = "tab" })
          end)
          bnmap("go", b.lsp_document_symbols)
          bnmap("gS", b.lsp_dynamic_workspace_symbols)
          bnmap("ge", function()
            b.lsp_document_diagnostics({ initial_mode = "normal" })
          end)
          bnmap("gE", function()
            b.lsp_workspace_diagnostics({ initial_mode = "normal" })
          end)
          bnmap("gr", function()
            b.lsp_references({ initial_mode = "normal" })
          end)
          bnmap("gic", function()
            b.lsp_incoming_calls({ initial_mode = "normal" })
          end)
          bnmap("goc", function()
            b.lsp_outgoing_calls({ initial_mode = "normal" })
          end)
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
    },
  },
}
