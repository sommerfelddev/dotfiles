local M = {}
local map = require("mapper")
local lspconfig = require("lspconfig")

function M.on_attach_wrapper(client, bufnr, opts)
  local autocmd = vim.api.nvim_create_autocmd

  if client.supports_method("textDocument/codeLens") then
    autocmd(
      { "CursorHold", "CursorHoldI", "InsertLeave" },
      { buffer = bufnr, callback = vim.lsp.codelens.refresh }
    )
    map.n("gl", vim.lsp.codelens.run, { buffer = bufnr })
  end

  map.n("<c-]>", vim.lsp.buf.definition, { buffer = bufnr })
  map.n("gD", vim.lsp.buf.declaration, { buffer = bufnr })
  map.n("gR", vim.lsp.buf.rename, { buffer = bufnr })
  map.n("ga", vim.lsp.buf.code_action, { buffer = bufnr })
  map.v("ga", vim.lsp.buf.code_action, { buffer = bufnr })
end

function M.switch_source_header_splitcmd(bufnr, splitcmd)
  bufnr = lspconfig.util.validate_bufnr(bufnr)
  local clangd_client = lspconfig.util.get_active_client_by_name(
    bufnr,
    "clangd"
  )
  local params = { uri = vim.uri_from_bufnr(bufnr) }
  if clangd_client then
    clangd_client.request(
      "textDocument/switchSourceHeader",
      params,
      function(err, result)
        if err then
          error(tostring(err))
        end
        if not result then
          print("Corresponding file cannot be determined")
          return
        end
        vim.api.nvim_command(splitcmd .. " " .. vim.uri_to_fname(result))
      end,
      bufnr
    )
  else
    print(
      "method textDocument/switchSourceHeader is not supported by any servers active on the current buffer"
    )
  end
end

return M
