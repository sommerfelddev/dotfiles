require("blink.compat").setup({})

require("blink.cmp").setup({
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
        columns = { { "kind_icon" }, { "label", gap = 1 } },
        components = {
          label = {
            text = function(ctx)
              return require("colorful-menu").blink_components_text(ctx)
            end,
            highlight = function(ctx)
              return require("colorful-menu").blink_components_highlight(ctx)
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
        score_offset = 100,
      },
      dap = { name = "dap", module = "blink.compat.source" },
    },
  },
})

require("blink.pairs").setup({
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
})
