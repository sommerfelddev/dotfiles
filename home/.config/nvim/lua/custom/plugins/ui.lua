return {
  {
    "sainnhe/gruvbox-material",
    priority = 1000,
    config = function()
      vim.g.gruvbox_material_background = "hard"
      vim.g.gruvbox_material_enable_bold = 1
      vim.g.gruvbox_material_enable_italic = 1
      vim.g.gruvbox_material_better_performance = 1
      vim.g.gruvbox_material_palette = "original"

      vim.cmd([[ colorscheme  gruvbox-material]])
    end
  },
  {
    "norcalli/nvim-colorizer.lua",
    event = "BufRead",
    config = true
  },
  {
    "lukas-reineke/indent-blankline.nvim",
    config = function()
      local highlight = {
        "RainbowRed",
        "RainbowYellow",
        "RainbowBlue",
        "RainbowOrange",
        "RainbowGreen",
        "RainbowViolet",
        "RainbowCyan",
      }
      local hooks = require "ibl.hooks"
      -- create the highlight groups in the highlight setup hook, so they are reset
      -- every time the colorscheme changes
      hooks.register(hooks.type.HIGHLIGHT_SETUP, function()
        vim.api.nvim_set_hl(0, "RainbowRed", { fg = "#E06C75" })
        vim.api.nvim_set_hl(0, "RainbowYellow", { fg = "#E5C07B" })
        vim.api.nvim_set_hl(0, "RainbowBlue", { fg = "#61AFEF" })
        vim.api.nvim_set_hl(0, "RainbowOrange", { fg = "#D19A66" })
        vim.api.nvim_set_hl(0, "RainbowGreen", { fg = "#98C379" })
        vim.api.nvim_set_hl(0, "RainbowViolet", { fg = "#C678DD" })
        vim.api.nvim_set_hl(0, "RainbowCyan", { fg = "#56B6C2" })
      end)

      vim.g.rainbow_delimiters = { highlight = highlight }
      require("ibl").setup { scope = { highlight = highlight } }

      hooks.register(hooks.type.SCOPE_HIGHLIGHT,
        hooks.builtin.scope_highlight_from_extmark)
    end
  },
  {
    'nvim-lualine/lualine.nvim',
    opts = {
      options = {
        icons_enabled = false,
        theme = 'gruvbox_dark',
        component_separators = '',
        section_separators = '|',
      },
      sections = {
        lualine_a = { 'filetype', { 'filename', path = 1 } },
        lualine_b = { '%l/%L:%c:%o' },
        lualine_c = { 'diff' },
        lualine_x = { 'searchcount, selectioncount' },
        lualine_y = {},
        lualine_z = { 'diagnostics' }
      },
      inactive_sections = {
        lualine_a = {},
        lualine_b = {},
        lualine_c = { 'filename' },
        lualine_x = {},
        lualine_y = {},
        lualine_z = {}
      },
    },
  },
  "https://gitlab.com/HiPhish/rainbow-delimiters.nvim",
}
