return {
  {
    "zbirenbaum/copilot.lua",
    cmd = "Copilot",
    build = ":Copilot auth",
    event = "InsertEnter",
    dependencies = {
      {
        "copilotlsp-nvim/copilot-lsp",
        init = function()
          vim.g.copilot_nes_debounce = 500
        end,
      },
    },
    keys = {
      {
        "<leader>tc",
        function()
          require("copilot.command").toggle()
        end,
        desc = "[T]oggle [C]opilot attachment",
      },
    },
    opts = {
      suggestion = { enabled = false },
      panel = { enabled = false },
      server_opts_overrides = {
        settings = {
          telemetry = {
            telemetryLevel = "off",
          },
        },
      },
      nes = {
        enabled = true,
        keymap = {
          accept_and_goto = "<leader>p",
          accept = false,
          dismiss = "<Esc>",
        },
      },
    },
  },
  {
    "olimorris/codecompanion.nvim",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "ravitemer/mcphub.nvim",
    },
    keys = {
      {
        "<leader>aa",
        "<cmd>CodeCompanionActions<cr>",
        mode = { "n", "v" },
        noremap = true,
        silent = true,
        desc = "[A]I [A]ctions",
      },
      {
        "<leader>ta",
        "<cmd>CodeCompanionChat Toggle<cr>",
        mode = { "n", "v" },
        noremap = true,
        silent = true,
        desc = "[T]oggle [A]I chat",
      },
      {
        "<leader>ac",
        "<cmd>CodeCompanionChat Add<cr>",
        mode = "v",
        noremap = true,
        silent = true,
        desc = "[A]I [C]hat add",
      },
    },
    opts = {
      strategies = {
        chat = {
          adapter = "copilot",
        },
        inline = {
          adapter = "copilot",
        },
      },
      extensions = {
        mcphub = {
          callback = "mcphub.extensions.codecompanion",
          opts = {
            make_vars = true,
            make_slash_commands = true,
            show_result_in_chat = true,
          },
        },
      },
    },
  },
}
