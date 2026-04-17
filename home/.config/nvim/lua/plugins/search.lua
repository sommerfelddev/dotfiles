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
        mode = "n",
        desc = "[G]it buffer [C]commits",
      },
      {
        "<localleader>gc",
        function()
          require("fzf-lua").git_bcommits_range()
        end,
        mode = "v",
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
      fzflua.register_ui_select()
    end,
  },
}
