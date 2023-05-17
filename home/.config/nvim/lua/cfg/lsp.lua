return {
  on_attach_wrapper = function(client, bufnr, opts)
    local map = require("mapper")
    local autocmd = vim.api.nvim_create_autocmd

    opts = vim.tbl_extend("force", { auto_format = false }, opts or {})

    if client.supports_method("textDocument/codeLens") then
      require("virtualtypes").on_attach(client, bufnr)
      autocmd(
        { "CursorHold", "CursorHoldI", "InsertLeave" },
        { buffer = bufnr, callback = vim.lsp.codelens.refresh }
      )
      map.n("gl", vim.lsp.codelens.run, { buffer = bufnr })
    end

    if client.supports_method("textDocument/definition") then
      map.n("<c-]>", vim.lsp.buf.definition, { buffer = bufnr })
    end
    if client.supports_method("textDocument/declaration") then
      map.n("gD", vim.lsp.buf.declaration, { buffer = bufnr })
    end
    if client.supports_method("textDocument/signatureHelp") then
      require("lsp_signature").on_attach(client, bufnr)
      map.n("gs", vim.lsp.buf.signature_help, { buffer = bufnr })
    end
    if client.supports_method("textDocument/rename") then
      map.n("gR", vim.lsp.buf.rename, { buffer = bufnr })
    end
    if client.supports_method("textDocument/codeAction") then
      map.n("ga", vim.lsp.buf.code_action, { buffer = bufnr })
      map.v("ga", vim.lsp.buf.code_action, { buffer = bufnr })
    end

    local buf_async_format = function()
      vim.lsp.buf.format(
        { bufnr = bufnr, async = true, id = client.id })
    end
    local buf_sync_format = function()
      vim.lsp.buf.format(
        { bufnr = bufnr, async = false, id = client.id })
    end
    local buf_async_format_hunks = function()
      require("cfg.utils").format_hunks(
        { bufnr = bufnr, async = true, id = client.id })
    end

    if client.supports_method("textDocument/formatting") then
      map.n("<leader>f", buf_async_format, { buffer = bufnr })
      if opts.auto_format then
        autocmd(
          "BufWritePre",
          { buffer = bufnr, callback = buf_sync_format }
        )
      end
    end
    if client.supports_method("textDocument/rangeFormatting") then
      map.v("<leader>f", buf_async_format, { buffer = bufnr })
      map.n("<leader>hf", buf_async_format_hunks, { buffer = bufnr })
    end

    require("lsp-inlayhints").on_attach(client, bufnr, false)
  end
}
