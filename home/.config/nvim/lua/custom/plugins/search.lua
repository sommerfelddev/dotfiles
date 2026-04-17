return {
  {
    "ibhagwan/fzf-lua",
    branch = "main",
    keys = {
      {
        "<localleader>b",
        function()
          require("fzf-lua").buffers()
        end,
        desc = "fzf-lua by [G]rep",
      },
      {
        "<localleader>g",
        function()
          require("fzf-lua").live_grep()
        end,
        desc = "fzf-lua by [G]rep",
      },
      {
        "<localleader>f",
        function()
          require("fzf-lua").files()
        end,
        desc = "fzf-lua [F]iles",
      },
      {
        "<leader><leader>",
        function()
          require("fzf-lua").global()
        end,
        desc = "fzf-lua global picker",
      },
      {
        "<localleader>d",
        function()
          require("fzf-lua").diagnostics()
        end,
        desc = "fzf-lua [D]iagnostics",
      },
      {
        "<localleader>r",
        function()
          require("fzf-lua").resume()
        end,
        desc = "fzf-lua [R]esume",
      },
      {
        "<localleader>gc",
        function()
          require("fzf-lua").git_bcommits()
        end,
        desc = "[G]it buffer [C]commits",
      },
      {
        "<localleader>gc",
        function()
          require("fzf-lua").git_bcommits_range()
        end,
        desc = "[G]it [C]commits for selected range",
      },
      {
        "<localleader>gC",
        function()
          require("fzf-lua").git_commits()
        end,
        desc = "[G]it (all) [C]commits",
      },
      {
        "<localleader>gb",
        function()
          require("fzf-lua").git_branches()
        end,
        desc = "[G]it [B]ranches",
      },
      {
        "<localleader>gs",
        function()
          require("fzf-lua").git_status()
        end,
        desc = "[G]it [S]tatus",
      },
      {
        "<localleader>gS",
        function()
          require("fzf-lua").git_stash()
        end,
        desc = "[G]it [S]tash",
      },
    },
    config = function()
      local fzflua = require("fzf-lua")
      fzflua.setup({
        keymap = {
          builtin = {
            true,
            ["<M-p>"] = "toggle-preview",
          },
        },
        grep = {
          hidden = true,
          RIPGREP_CONFIG_PATH = "~/.config/ripgrep/ripgreprc",
        },
        lsp = {
          includeDeclaration = false,
        },
        actions = {
          files = {
            true,
            ["ctrl-x"] = fzflua.actions.file_split,
          },
        },
      })
      vim.api.nvim_create_autocmd("LspAttach", {
        callback = function(event)
          local bnmap = function(keys, func, desc)
            vim.keymap.set(
              "n",
              keys,
              func,
              { buffer = event.buf, desc = "LSP: " .. desc }
            )
          end
          bnmap("gd", fzflua.lsp_definitions, "[G]oto [D]efinition")
          bnmap("gvd", function()
            fzflua.lsp_definitions({ jump1_action = fzflua.actions.file_vsplit })
          end, "[G]oto in a [V]ertical split to [D]efinition")
          bnmap("gxd", function()
            fzflua.lsp_definitions({ jump1_action = fzflua.actions.file_split })
          end, "[G]oto in a [X]horizontal split to [D]efinition")
          bnmap("gtd", function()
            fzflua.lsp_definitions({
              jump1_action = fzflua.actions.file_tabedit,
            })
          end, "[G]oto in a [T]ab to [D]efinition")
          bnmap("<leader>D", fzflua.lsp_typedefs, "Type [D]efinition")
          bnmap("<leader>vD", function()
            fzflua.lsp_typedefs({ jump1_action = fzflua.actions.file_vsplit })
          end, "Open in a [V]ertical split Type [D]efinition")
          bnmap("<leader>xD", function()
            fzflua.lsp_typedefs({ jump1_action = fzflua.actions.file_split })
          end, "Open in a [X]horizontal split Type [D]efinition")
          bnmap("<leader>tD", function()
            fzflua.lsp_typedefs({ jump1_action = fzflua.actions.file_tabedit })
          end, "Open in a [T]ab Type [D]efinition")
          bnmap("gri", fzflua.lsp_implementations, "[G]oto [I]mplementation")
          bnmap("grvi", function()
            fzflua.lsp_implementations({
              jump1_action = fzflua.actions.file_vsplit,
            })
          end, "[G]oto in a [V]ertical split to [I]mplementation")
          bnmap("grxi", function()
            fzflua.lsp_implementations({
              jump1_action = fzflua.actions.file_split,
            })
          end, "[G]oto in a [X]horizontal split to [I]mplementation")
          bnmap("grti", function()
            fzflua.lsp_implementations({
              jump1_action = fzflua.actions.file_tabedit,
            })
          end, "[G]oto in a [T]ab to [I]mplementation")
          bnmap("grr", fzflua.lsp_references, "[G]oto [R]eferences")
          bnmap("<leader>ic", fzflua.lsp_incoming_calls, "[I]ncoming [C]alls")
          bnmap("<leader>oc", fzflua.lsp_outgoing_calls, "[O]utgoing [C]alls")
          bnmap("gO", fzflua.lsp_document_symbols, "d[O]ocument symbols")
          bnmap(
            "<leader>ws",
            fzflua.lsp_live_workspace_symbols,
            "[W]orkspace [S]ymbols"
          )
          bnmap(
            "<leader>wd",
            fzflua.diagnostics_workspace,
            "[W]orkspace [D]iagnostics"
          )
        end,
      })
      fzflua.register_ui_select()
    end,
  },
}
