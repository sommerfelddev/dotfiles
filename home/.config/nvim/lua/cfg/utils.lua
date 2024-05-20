local M = {}
local gitsigns = require("gitsigns")
local conform = require("conform")

function M.format_hunks(options)
  local hunks = gitsigns.get_hunks()
  if not hunks or vim.tbl_isempty(hunks) then
    return
  end
  for _, hunk in ipairs(hunks) do
    if hunk and hunk.added then
      local start = hunk.added.start
      local last = start + hunk.added.count
      -- nvim_buf_get_lines uses zero-based indexing -> subtract from last
      local last_hunk_line = vim.api.nvim_buf_get_lines(0, last - 2, last - 1, true)[1]
      local range = { start = { start, 0 }, ["end"] = { last - 1, last_hunk_line:len() } }
      options = vim.tbl_extend("force", { range = range, lsp_fallback = true, quiet = true }, options or {})
      conform.format(options)
    end
  end
end

return M
