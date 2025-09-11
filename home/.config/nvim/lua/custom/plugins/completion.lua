return {
  {
    "zbirenbaum/copilot.lua",
    cmd = "Copilot",
    build = ":Copilot auth",
    event = "InsertEnter",
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
    },
  },
  {
    "saghen/blink.compat",
    opts = {},
  },
  {
    "saghen/blink.cmp",
    dependencies = {
      "rafamadriz/friendly-snippets",
      "fang2hou/blink-copilot",
      "rcarriga/cmp-dap",
    },
    opts = {
      keymap = {
        preset = "cmdline",
        ["<CR>"] = { "accept", "fallback" },
      },
      appearance = {
        use_nvim_cmp_as_default = true,
      },
      completion = {
        list = {
          selection = {
            preselect = function()
              return not require("blink.cmp").snippet_active({ direction = 1 })
            end,
          },
        },
        documentation = { auto_show = true },
      },
      signature = {
        enabled = true,
        trigger = {
          enabled = true,
          show_on_keyword = true,
          show_on_insert = true,
        },
      },
      sources = {
        default = { "lazydev", "lsp", "copilot", "snippets", "path", "buffer" },
        per_filetype = {
          ["dap-repl"] = { "dap" },
        },
        providers = {
          path = {
            opts = {
              get_cwd = vim.fn.getcwd,
            },
          },
          copilot = {
            name = "copilot",
            module = "blink-copilot",
            score_offset = 100,
            async = true,
          },
          lazydev = {
            name = "LazyDev",
            module = "lazydev.integrations.blink",
            -- make lazydev completions top priority (see `:h blink.cmp`)
            score_offset = 100,
          },
          dap = { name = "dap", module = "blink.compat.source" },
        },
      },
    },
  },
  {
    "saghen/blink.pairs",
    version = "*",
    dependencies = "saghen/blink.download",
    opts = {
      mappings = {
        disabled_filetypes = { "TelescopePrompt" },
      },
    },
  },
}
