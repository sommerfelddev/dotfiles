return {
  {
    "folke/lazydev.nvim",
    ft = "lua",
    opts = {
      library = {
        { path = "${3rd}/luv/library", words = { "vim%.uv" } },
      },
    },
  },
  {
    "neovim/nvim-lspconfig",
    version = false,
    dependencies = {
      { "j-hui/fidget.nvim", opts = {} },
      "saghen/blink.cmp",
      { "williamboman/mason.nvim", opts = {} },
      {
        "williamboman/mason-lspconfig.nvim",
        opts = {
          ensure_installed = {},
          automatic_installation = false,
          handlers = {
            function(server_name)
              vim.lsp.enable(server_name)
            end,
          },
        },
      },
      {
        "WhoIsSethDaniel/mason-tool-installer.nvim",
        opts = {
          ensure_installed = {
            "actionlint",
            "autotools-language-server",
            "basedpyright",
            "bash-language-server",
            "clangd",
            "codelldb",
            "codespell",
            "css-lsp",
            "dockerfile-language-server",
            "gh",
            "gh-actions-language-server",
            "groovy-language-server",
            "hadolint",
            "html-lsp",
            "jq",
            "json-lsp",
            "jsonlint",
            "just-lsp", -- "Platform unsupported"
            "lua-language-server",
            "markdownlint",
            "mdformat",
            "neocmakelsp",
            "nginx-config-formatter",
            "nginx-language-server", -- needs python <= 3.12
            "npm-groovy-lint",
            "prettier",
            "ruff",
            "rust-analyzer",
            "shellcheck",
            "shellharden",
            "shfmt",
            "stylelint",
            "stylua",
            "systemd-lsp",
            "systemdlint",
            "typescript-language-server",
            "typos",
            "yaml-language-server",
            "yamllint",
            "yq",
            -- "fortls",
          },
        },
      },
    },
    config = function()
      vim.lsp.enable("just")
      vim.lsp.enable("tblgen_lsp_server")

      vim.api.nvim_create_autocmd("LspAttach", {
        group = vim.api.nvim_create_augroup("lsp-attach", { clear = true }),
        callback = function(event)
          local bufnr = event.buf

          local function map(mode, l, r, desc)
            vim.keymap.set(
              mode,
              l,
              r,
              { buffer = bufnr, desc = "LSP: " .. desc }
            )
          end
          local function nmap(l, r, desc)
            map("n", l, r, desc)
          end
          nmap("<c-]>", vim.lsp.buf.definition, "Goto definition")
          nmap("gD", vim.lsp.buf.declaration, "[G]oto [D]eclaration")

          local fzf = require("fzf-lua")
          nmap("gd", fzf.lsp_definitions, "[G]oto [D]efinition")
          nmap("gvd", function()
            fzf.lsp_definitions({ jump1_action = fzf.actions.file_vsplit })
          end, "[G]oto in a [V]ertical split to [D]efinition")
          nmap("gxd", function()
            fzf.lsp_definitions({ jump1_action = fzf.actions.file_split })
          end, "[G]oto in a [X]horizontal split to [D]efinition")
          nmap("gtd", function()
            fzf.lsp_definitions({ jump1_action = fzf.actions.file_tabedit })
          end, "[G]oto in a [T]ab to [D]efinition")
          nmap("<leader>D", fzf.lsp_typedefs, "Type [D]efinition")
          nmap("<leader>vD", function()
            fzf.lsp_typedefs({ jump1_action = fzf.actions.file_vsplit })
          end, "Open in a [V]ertical split Type [D]efinition")
          nmap("<leader>xD", function()
            fzf.lsp_typedefs({ jump1_action = fzf.actions.file_split })
          end, "Open in a [X]horizontal split Type [D]efinition")
          nmap("<leader>tD", function()
            fzf.lsp_typedefs({ jump1_action = fzf.actions.file_tabedit })
          end, "Open in a [T]ab Type [D]efinition")
          nmap("gri", fzf.lsp_implementations, "[G]oto [I]mplementation")
          nmap("grvi", function()
            fzf.lsp_implementations({ jump1_action = fzf.actions.file_vsplit })
          end, "[G]oto in a [V]ertical split to [I]mplementation")
          nmap("grxi", function()
            fzf.lsp_implementations({ jump1_action = fzf.actions.file_split })
          end, "[G]oto in a [X]horizontal split to [I]mplementation")
          nmap("grti", function()
            fzf.lsp_implementations({ jump1_action = fzf.actions.file_tabedit })
          end, "[G]oto in a [T]ab to [I]mplementation")
          nmap("grr", fzf.lsp_references, "[G]oto [R]eferences")
          nmap("<leader>ic", fzf.lsp_incoming_calls, "[I]ncoming [C]alls")
          nmap("<leader>oc", fzf.lsp_outgoing_calls, "[O]utgoing [C]alls")
          nmap("gO", fzf.lsp_document_symbols, "d[O]ocument symbols")
          nmap(
            "<leader>ws",
            fzf.lsp_live_workspace_symbols,
            "[W]orkspace [S]ymbols"
          )
          nmap(
            "<leader>wd",
            fzf.diagnostics_workspace,
            "[W]orkspace [D]iagnostics"
          )

          local client = vim.lsp.get_client_by_id(event.data.client_id)
          if
            client
            and client:supports_method(
              vim.lsp.protocol.Methods.textDocument_documentHighlight,
              event.buf
            )
          then
            local highlight_augroup =
              vim.api.nvim_create_augroup("lsp-highlight", { clear = false })
            vim.api.nvim_create_autocmd({ "CursorHold", "CursorHoldI" }, {
              buffer = event.buf,
              group = highlight_augroup,
              callback = vim.lsp.buf.document_highlight,
            })

            vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
              buffer = event.buf,
              group = highlight_augroup,
              callback = vim.lsp.buf.clear_references,
            })

            vim.api.nvim_create_autocmd("LspDetach", {
              group = vim.api.nvim_create_augroup(
                "lsp-detach",
                { clear = true }
              ),
              callback = function(event2)
                vim.lsp.buf.clear_references()
                vim.api.nvim_clear_autocmds({
                  group = "lsp-highlight",
                  buffer = event2.buf,
                })
              end,
            })
          end

          if
            client
            and client:supports_method(
              vim.lsp.protocol.Methods.textDocument_codeLens,
              event.buf
            )
          then
            vim.api.nvim_create_autocmd(
              { "CursorHold", "CursorHoldI", "InsertLeave" },
              {
                buffer = bufnr,
                group = vim.api.nvim_create_augroup(
                  "codelens",
                  { clear = true }
                ),
                callback = vim.lsp.codelens.refresh,
              }
            )
          end

          if
            client
            and client:supports_method(
              vim.lsp.protocol.Methods.textDocument_inlayHint,
              event.buf
            )
          then
            nmap("<leader>th", function()
              vim.lsp.inlay_hint.enable(
                not vim.lsp.inlay_hint.is_enabled({ bufnr = event.buf })
              )
            end, "[T]oggle Inlay [H]ints")
          end
        end,
      })
    end,
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
        desc = "[F]ormat buffer",
      },
    },
    config = function()
      require("conform").setup({
        formatters_by_ft = {
          awk = { "gawk" },
          bash = { "shfmt" },
          cmake = { "cmake_format" },
          css = { "prettier", "stylelint" },
          groovy = { "npm-groovy-lint" },
          html = { "prettier" },
          javascript = { "prettier" },
          typescript = { "prettier" },
          jenkins = { "npm-groovy-lint" },
          json = { "jq", "jsonlint" },
          jsonc = { "prettier" },
          just = { "just" },
          markdown = { "mdformat" },
          nginx = { "nginxfmt" },
          lua = { "stylua" },
          python = { "ruff_format", "ruff_fix", "ruff_organize_imports" },
          rust = { "rustfmt" },
          sh = { "shfmt", "shellcheck", "shellharden" },
          yaml = { "yamllint" },
          zsh = { "shfmt", "shellcheck", "shellharden" },
        },
        default_format_opts = {
          lsp_format = "fallback",
        },
        formatters = {
          shfmt = {
            prepend_args = { "-i", "2" },
          },
        },
      })
      vim.o.formatexpr = "v:lua.require'conform'.formatexpr()"
    end,
  },
  {
    "mrcjkb/rustaceanvim",
    ft = "rust",
  },
  {
    "mfussenegger/nvim-lint",
    event = { "BufReadPre", "BufNewFile" },
    config = function()
      local lint = require("lint")

      lint.linters_by_ft = {
        css = { "stylelint" },
        dockerfile = { "hadolint" },
        groovy = { "npm-groovy-lint" },
        jenkins = { "npm-groovy-lint" },
        json = { "jsonlint" },
        markdown = { "markdownlint" },
        makefile = { "checkmake" },
        systemd = { "systemdlint" },
        yaml = { "yamllint", "yq" },
        ghaction = { "actionlint" },
        zsh = { "zsh" },
        ["*"] = { "codespell", "typos" },
      }
      local lint_augroup = vim.api.nvim_create_augroup("lint", { clear = true })
      vim.api.nvim_create_autocmd({ "BufReadPost", "BufWritePost" }, {
        group = lint_augroup,
        callback = function()
          if vim.opt_local.modifiable:get() then
            lint.try_lint()
          end
        end,
      })
    end,
  },
  {
    "rachartier/tiny-inline-diagnostic.nvim",
    event = "VeryLazy",
    priority = 1000,
    opts = {
      options = {
        show_source = {
          if_many = true,
        },
        -- Set the arrow icon to the same color as the first diagnostic severity
        set_arrow_to_diag_color = true,
        -- Configuration for multiline diagnostics
        -- Can be a boolean or a table with detailed options
        multilines = {
          -- Enable multiline diagnostic messages
          enabled = true,
        },

        -- Display all diagnostic messages on the cursor line, not just those under cursor
        show_all_diags_on_cursorline = true,
        -- Enable diagnostics in Select mode (e.g., when auto-completing with Blink)
        enable_on_select = true,
        -- Configuration for breaking long messages into separate lines
        break_line = {
          -- Enable breaking messages after a specific length
          enabled = true,
        },
        -- Filter diagnostics by severity levels
        -- Available severities: vim.diagnostic.severity.ERROR, WARN, INFO, HINT
        severity = {
          vim.diagnostic.severity.ERROR,
          vim.diagnostic.severity.WARN,
          vim.diagnostic.severity.INFO,
          vim.diagnostic.severity.HINT,
        },
      },
    },
  },
}
