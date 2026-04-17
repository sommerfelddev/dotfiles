-- blink.indent (gruvbox setup is in init.lua)
require("blink.indent").setup({
  scope = {
    highlights = {
      "BlinkIndentOrange",
      "BlinkIndentViolet",
      "BlinkIndentBlue",
      "BlinkIndentRed",
      "BlinkIndentCyan",
      "BlinkIndentYellow",
      "BlinkIndentGreen",
    },
    underline = {
      enabled = true,
      highlights = {
        "BlinkIndentOrangeUnderline",
        "BlinkIndentVioletUnderline",
        "BlinkIndentBlueUnderline",
        "BlinkIndentRedUnderline",
        "BlinkIndentCyanUnderline",
        "BlinkIndentYellowUnderline",
        "BlinkIndentGreenUnderline",
      },
    },
  },
})

require("lualine").setup({
  options = {
    icons_enabled = false,
    theme = "gruvbox_dark",
    component_separators = "",
    section_separators = "|",
    disabled_filetypes = {
      winbar = {
        "dap-view",
        "dap-repl",
        "dap-view-term",
      },
    },
  },
  sections = {
    lualine_a = { "filetype", { "filename", path = 1 } },
    lualine_b = { "%l/%L:%c:%o" },
    lualine_c = { "diff" },
    lualine_x = { "searchcount", "selectioncount" },
    lualine_y = { "overseer", "copilot" },
    lualine_z = { "diagnostics" },
  },
  inactive_sections = {
    lualine_a = {},
    lualine_b = {},
    lualine_c = { "filename" },
    lualine_x = {},
    lualine_y = {},
    lualine_z = {},
  },
})
