local function validate_bufnr(bufnr)
  vim.validate("bufnr", bufnr, "number")
  return bufnr == 0 and vim.api.nvim_get_current_buf() or bufnr
end

local function switch_source_header_splitcmd(bufnr, splitcmd)
  local method_name = "textDocument/switchSourceHeader"
  bufnr = validate_bufnr(bufnr)
  local client = vim.lsp.get_clients({ bufnr = bufnr, name = "clangd" })[1]
  if not client then
    return vim.notify(
      ("method %s is not supported by any servers active on the current buffer"):format(
        method_name
      )
    )
  end
  local params = vim.lsp.util.make_text_document_params(bufnr)
  client.request(method_name, params, function(err, result)
    if err then
      error(tostring(err))
    end
    if not result then
      vim.notify("corresponding file cannot be determined")
      return
    end
    vim.api.nvim_cmd({
      cmd = splitcmd,
      args = { vim.uri_to_fname(result) },
    }, {})
  end, bufnr)
end

return {
  capabilities = {
    offsetEncoding = { "utf-16" },
  },
  on_attach = function(_, bufnr)
    local function nmap(l, r, desc)
      vim.keymap.set("n", l, r, { buffer = bufnr, desc = desc })
    end
    nmap("gH", function()
      switch_source_header_splitcmd(bufnr, "edit")
    end, "[G]o to [H]eader")
    nmap("gvH", function()
      switch_source_header_splitcmd(bufnr, "vsplit")
    end, "[G]o in a [V]ertical split to [H]eader")
    nmap("gxH", function()
      switch_source_header_splitcmd(bufnr, "split")
    end, "[G]o in a [X]horizontal split to [H]eader")
    nmap("gtH", function()
      switch_source_header_splitcmd(bufnr, "tabedit")
    end, "[G]o in a [T]ab to [H]eader")
  end,
  init_options = {
    clangdFileStatus = true,
  },
}
