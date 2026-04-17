return {
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
      "xzbdmw/colorful-menu.nvim",
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
        menu = {
          draw = {
            -- treesitter = { "lsp" },
            -- We don't need label_description now because label and label_description are already
            -- combined together in label by colorful-menu.nvim.
            columns = { { "kind_icon" }, { "label", gap = 1 } },
            components = {
              label = {
                text = function(ctx)
                  return require("colorful-menu").blink_components_text(ctx)
                end,
                highlight = function(ctx)
                  return require("colorful-menu").blink_components_highlight(
                    ctx
                  )
                end,
              },
            },
          },
        },
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
        disabled_filetypes = {},
      },
      highlights = {
        groups = {
          "BlinkIndentOrange",
          "BlinkIndentViolet",
          "BlinkIndentBlue",
          "BlinkIndentRed",
          "BlinkIndentCyan",
          "BlinkIndentYellow",
          "BlinkIndentGreen",
        },
      },
    },
  },
}
