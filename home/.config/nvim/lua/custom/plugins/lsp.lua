local map = require("mapper")

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
      local cfg_lsp = require "cfg.lsp"
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
          commands = {
            ClangdSwitchSourceHeader = {
              function()
                cfg_lsp.switch_source_header_splitcmd(0, "edit")
              end,
              description = "Open source/header in current buffer",
            },
            ClangdSwitchSourceHeaderVSplit = {
              function()
                cfg_lsp.switch_source_header_splitcmd(0, "vsplit")
              end,
              description = "Open source/header in a new vsplit",
            },
            ClangdSwitchSourceHeaderSplit = {
              function()
                cfg_lsp.lsp.switch_source_header_splitcmd(0, "split")
              end,
              description = "Open source/header in a new split",
            },
            ClangdSwitchSourceHeaderTab = {
              function()
                cfg_lsp.lsp.switch_source_header_splitcmd(0, "tabedit")
              end,
              description = "Open source/header in a new tab",
            },
          },
          on_attach = function(_, bufnr)
            map.ncmd("gH", "ClangdSwitchSourceHeader", { buffer = bufnr })
            map.ncmd("gvH", "ClangdSwitchSourceHeaderVSplit", { buffer = bufnr })
            map.ncmd("gxH", "ClangdSwitchSourceHeaderSplit", { buffer = bufnr })
            map.ncmd("gtH", "ClangdSwitchSourceHeaderSplit", { buffer = bufnr })

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
          local client = vim.lsp.get_client_by_id(args.data.client_id)
          cfg_lsp.on_attach_wrapper(client, bufnr)
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
        c = { "clang-format" },
        cpp = { "clang-format" },
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
}
