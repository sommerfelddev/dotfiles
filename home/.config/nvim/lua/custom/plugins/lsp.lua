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
    "lewis6991/hover.nvim",
    keys = {
      {
        "K",
        function()
          require("hover").open()
        end,
        desc = "Hover",
      },
      {
        "gK",
        function()
          require("hover").enter()
        end,
        desc = "Hover Enter",
      },
      {
        "gh",
        function()
          require("hover").open()
        end,
        desc = "[H]over",
      },
    },
    config = function()
      require("hover").config({
        --- List of modules names to load as providers.
        --- @type (string|Hover.Config.Provider)[]
        providers = {
          "hover.providers.diagnostic",
          "hover.providers.lsp",
          "hover.providers.dap",
          "hover.providers.man",
          "hover.providers.dictionary",
          -- Optional, disabled by default:
          "hover.providers.gh",
          -- 'hover.providers.gh_user',
          -- 'hover.providers.jira',
          "hover.providers.fold_preview",
          -- 'hover.providers.highlight',
        },
      })
    end,
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
            -- "nginx-language-server", -- needs python <= 3.12
            -- "just-lsp", -- "Platform unsupported"
            "actionlint",
            "autotools-language-server",
            "bash-language-server",
            "clangd",
            "codelldb",
            "codespell",
            "css-lsp",
            "dockerfile-language-server",
            "fortls",
            "gh",
            "gh-actions-language-server",
            "groovy-language-server",
            "hadolint",
            "html-lsp",
            "jq",
            "jsonlint",
            "lua-language-server",
            "markdownlint",
            "mdformat",
            "neocmakelsp",
            "nginx-config-formatter",
            "npm-groovy-lint",
            "prettier",
            "ruff",
            "rust-analyzer",
            "shellcheck",
            -- "shellharden",
            "shfmt",
            "stylelint",
            "stylua",
            "systemd-language-server",
            "systemdlint",
            "typescript-language-server",
            "typos",
            "yamllint",
            "yq",
          },
        },
      },
    },
    config = function()
      vim.lsp.enable("just")
      vim.lsp.enable("tblgen_lsp_server")
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
          typecript = { "prettier" },
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
  { "j-hui/fidget.nvim", opts = {} },
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
