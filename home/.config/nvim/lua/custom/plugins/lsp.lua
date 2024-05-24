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
        ruff_lsp = {},
        pyright = {},
        clangd = {
          cmd = {
            "clangd",
            "--enable-config",
            "--completion-parse=auto",
            "--completion-style=bundled",
            "--header-insertion=iwyu",
            "--header-insertion-decorators",
            "--inlay-hints",
            "--suggest-missing-includes",
            "--folding-ranges",
            "--function-arg-placeholders",
            "--pch-storage=memory",
          },
          on_attach = function(_, bufnr)
            map.n("gH", edit_source_header, { buffer = bufnr })
            map.n("gvH", vsplit_source_header, { buffer = bufnr })
            map.n("gxH", split_source_header, { buffer = bufnr })
            map.n("gtH", tabedit_source_header, { buffer = bufnr })

            require("clangd_extensions.inlay_hints").setup_autocmd()
            require("clangd_extensions.inlay_hints").set_inlay_hints()
          end,
          init_options = {
            usePlaceholders = true,
            completeUnimported = true,
            clangdFileStatus = true,
          },
        },
      }

      for server, config in pairs(servers) do
        local default_config = lspconfig[server].default_config or
            lspconfig[server].document_config.default_config
        local cmd = config.cmd or default_config.cmd
        if vim.fn.executable(cmd[1]) == 1 then lspconfig[server].setup(config) end
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
        end,
      })
    end,
    dependencies = {
      { 'folke/neodev.nvim', opts = {} },
      {
        "p00f/clangd_extensions.nvim",
        config = function()
          require("clangd_extensions").setup({
          })
        end
      },
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
