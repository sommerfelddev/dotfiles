local map = require("mapper")

local function handler_splitcmd(_, uri, splitcmd)
  if not uri or uri == "" then
    vim.api.nvim_echo({ { "Corresponding file cannot be determined" } }, false, {})
    return
  end
  local file_name = vim.uri_to_fname(uri)
  vim.api.nvim_cmd({
    cmd = splitcmd,
    args = { file_name },
  }, {})
end

local function switch_source_header_splitcmd(bufnr, splitcmd)
  bufnr = bufnr or 0
  vim.lsp.buf_request(bufnr, "textDocument/switchSourceHeader", {
    uri = vim.uri_from_bufnr(bufnr),
  }, function(err, uri) return handler_splitcmd(err, uri, splitcmd) end)
end

local function edit_source_header(bufnr)
  switch_source_header_splitcmd(bufnr, "edit")
end

local function split_source_header(bufnr)
  switch_source_header_splitcmd(bufnr, "split")
end

local function vsplit_source_header(bufnr)
  switch_source_header_splitcmd(bufnr, "vsplit")
end

local function tabedit_source_header(bufnr)
  switch_source_header_splitcmd(bufnr, "tabedit")
end

return {
  {
    "lewis6991/hover.nvim",
    config = function()
      require("hover").setup {
        init = function()
          require("hover.providers.lsp")
          require('hover.providers.gh')
          require('hover.providers.man')
          -- require('hover.providers.dictionary')
        end,
      }

      vim.keymap.set("n", "K", require("hover").hover, { desc = "hover.nvim" })
      vim.keymap.set("n", "gh", require("hover").hover, { desc = "hover.nvim" })
      vim.keymap.set("n", "gK", require("hover").hover_select,
        { desc = "hover.nvim (select)" })
    end
  },
  {
    'neovim/nvim-lspconfig',
    config = function()
      local lspconfig = require("lspconfig")
      -- Enable (broadcasting) snippet capability for completion
      local capabilities = vim.lsp.protocol.make_client_capabilities()
      capabilities.textDocument.completion.completionItem.snippetSupport = true
      capabilities.workspace.didChangeWatchedFiles.dynamicRegistration = true
      if pcall(require, "cmp_nvim_lsp") then
        capabilities = require("cmp_nvim_lsp").default_capabilities()
      end

      lspconfig.util.default_config = vim.tbl_extend(
        "force",
        lspconfig.util.default_config,
        {
          capabilities = capabilities,
        }
      )

      local servers = {
        bashls = {},
        dockerls = {},
        fortls = {},
        lua_ls = {},
        ruff = {},
        ts_ls = {},
        pyright = {},
        clangd = {
          on_attach = function(_, bufnr)
            map.n("gH", edit_source_header, { buffer = bufnr })
            map.n("gvH", vsplit_source_header, { buffer = bufnr })
            map.n("gxH", split_source_header, { buffer = bufnr })
            map.n("gtH", tabedit_source_header, { buffer = bufnr })
          end,
          init_options = {
            clangdFileStatus = true,
          },
        },
      }

      for server, config in pairs(servers) do
        local cmd = config.cmd
        local config_def = lspconfig[server].config_def
        if not cmd and config_def then
          local default_config = config_def.default_config
          if default_config then
            cmd = default_config.cmd
          end
        end
        if cmd then
          if vim.fn.executable(cmd[1]) == 1 then
            lspconfig[server].setup(config)
          end
        end
      end

      vim.api.nvim_create_autocmd("LspAttach", {
        callback = function(args)
          local bufnr = args.buf
          local client = assert(vim.lsp.get_client_by_id(args.data.client_id))

          if client.supports_method("textDocument/codeLens") then
            vim.api.nvim_create_autocmd(
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

          -- The following two autocommands are used to highlight references of the
          -- word under your cursor when your cursor rests there for a little while.
          --    See `:help CursorHold` for information about when this is executed
          --
          -- When you move your cursor, the highlights will be cleared (the second autocommand).
          if client.server_capabilities.documentHighlightProvider then
            local highlight_augroup = vim.api.nvim_create_augroup('lsp-highlight', { clear = false })
            vim.api.nvim_create_autocmd({ 'CursorHold', 'CursorHoldI' }, {
              buffer = bufnr,
              group = highlight_augroup,
              callback = vim.lsp.buf.document_highlight,
            })

            vim.api.nvim_create_autocmd({ 'CursorMoved', 'CursorMovedI' }, {
              buffer = bufnr,
              group = highlight_augroup,
              callback = vim.lsp.buf.clear_references,
            })

            vim.api.nvim_create_autocmd('LspDetach', {
              group = vim.api.nvim_create_augroup('lsp-detach', { clear = true }),
              callback = function(event2)
                vim.lsp.buf.clear_references()
                vim.api.nvim_clear_autocmds { group = 'lsp-highlight', buffer = event2.buf }
              end,
            })
          end

          -- The following autocommand is used to enable inlay hints in your
          -- code, if the language server you are using supports them
          --
          -- This may be unwanted, since they displace some of your code
          if client.server_capabilities.inlayHintProvider and vim.lsp.inlay_hint then
            map.n('<leader>th', function()
              vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled({}))
            vim.lsp.inlay_hint.enable()
            end, { buffer = bufnr })
          end
        end,
      })
    end,
    dependencies = {
      { 'folke/neodev.nvim', opts = {} },
    },
  },
  {
    "ray-x/lsp_signature.nvim",
    event = "VeryLazy",
    config = function()
      local lsp_signature = require "lsp_signature"
      lsp_signature.setup({})

      vim.api.nvim_create_autocmd("LspAttach", {
        callback = function(args)
          local bufnr = args.buf
          local client = assert(vim.lsp.get_client_by_id(args.data.client_id))
          if client.supports_method("textDocument/signatureHelp") then
            require("lsp_signature").on_attach({}, bufnr)
            map.n("gs", vim.lsp.buf.signature_help, { buffer = bufnr })
          end
        end,
      })
    end
  },
  {
    "stevearc/conform.nvim",
    event = { "BufWritePre" },
    cmd = { "ConformInfo" },
    keys = {
      {
        "<leader>f",
        function()
          require("conform").format({ async = true, lsp_fallback = true })
        end,
        mode = "",
        desc = "Format buffer",
      },
    },
    opts = {
      formatters_by_ft = {
        python = { "ruff_format" },
        cmake = { "cmake_format" },
        json = { "jq" },
        rust = { "rustfmt" },
        sh = { "shfmt" },
        bash = { "shfmt" },
        zsh = { "shfmt" },
      },
      formatters = {
        shfmt = {
          prepend_args = { "-i", "2" },
        },
      },
    },
    init = function()
      vim.o.formatexpr = "v:lua.require'conform'.formatexpr()"
      vim.api.nvim_create_autocmd("BufWritePre", {
        callback = require "cfg.utils".format_hunks,
      })
    end,
  },
  {
    'mrcjkb/rustaceanvim',
    lazy = false,
  },
  {
    "mfussenegger/nvim-lint",
    event = { 'BufReadPre', 'BufNewFile' },
    config = function()
      local lint = require('lint')
      lint.linters_by_ft = {
        dockerfile = { "hadolint" },
      }
      vim.api.nvim_create_autocmd({ "BufReadPost", "BufWritePost", "InsertLeave" }, {
        callback = function()
          lint.try_lint()
        end
      })
    end
  },
  { "j-hui/fidget.nvim", opts = {} },
}
