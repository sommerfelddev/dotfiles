local M = {}
local gitsigns = require("gitsigns")

function M.format_hunks(options)
  local hunks = require("gitsigns").get_hunks()
  if not hunks or vim.tbl_isempty(hunks) then
    return
  end
  for _, hunk in ipairs(hunks) do
    local added = hunk.added
    if added then
      local start_line = added.start
      local count = added.count
      if start_line and count and start_line > 0 and count > 0 then
        local end_line = start_line + added.count - 1
        local range = { start = { start_line, 0 }, ["end"] = { end_line, 0 } }
        options = vim.tbl_extend("force", { range = range }, options or {})
        vim.lsp.buf.format(options)
      end
    end
  end
end

return M
