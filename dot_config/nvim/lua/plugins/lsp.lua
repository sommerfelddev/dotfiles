require("lazydev").setup({
  library = {
    { path = "${3rd}/luv/library", words = { "vim%.uv" } },
  },
})

vim.lsp.enable("just")
pcall(vim.lsp.enable, "tblgen_lsp_server")

require("fidget").setup({})

-- LSPs come from Home-Manager (see nix/common.nix). lspconfig ships the
-- default configs; we just opt-in per server. (Previously this was driven
-- by mason-lspconfig handlers; phase p6 of the nix migration removed
-- Mason entirely.)
vim.lsp.enable({
  "autotools_ls",
  "basedpyright",
  "bashls",
  "clangd",
  "cssls",
  "dockerls",
  "eslint",
  "gh_actions_ls",
  "html",
  "jsonls",
  "lua_ls",
  "neocmake",
  "ruff",
  "rust_analyzer",
  "systemd_ls",
  "taplo",
  "ts_ls",
  "yamlls",
})

vim.api.nvim_create_autocmd("LspAttach", {
  group = vim.api.nvim_create_augroup("lsp-attach", { clear = true }),
  callback = function(event)
    local bufnr = event.buf

    local function map(mode, l, r, desc)
      vim.keymap.set(mode, l, r, { buffer = bufnr, desc = "LSP: " .. desc })
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
    nmap("gvt", function()
      fzf.lsp_typedefs({ jump1_action = fzf.actions.file_vsplit })
    end, "[G]oto in a [V]ertical split to [T]ype definition")
    nmap("gxt", function()
      fzf.lsp_typedefs({ jump1_action = fzf.actions.file_split })
    end, "[G]oto in a [X]horizontal split to [T]ype definition")
    nmap("gtt", function()
      fzf.lsp_typedefs({ jump1_action = fzf.actions.file_tabedit })
    end, "[G]oto in a [T]ab to [T]ype definition")
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
    nmap("gvr", function()
      fzf.lsp_references({ jump1_action = fzf.actions.file_vsplit })
    end, "[G]oto in a [V]ertical split to [R]eferences")
    nmap("gxr", function()
      fzf.lsp_references({ jump1_action = fzf.actions.file_split })
    end, "[G]oto in a [X]horizontal split to [R]eferences")
    nmap("gtr", function()
      fzf.lsp_references({ jump1_action = fzf.actions.file_tabedit })
    end, "[G]oto in a [T]ab to [R]eferences")
    nmap("<leader>ci", fzf.lsp_incoming_calls, "[C]ode [I]ncoming calls")
    nmap("<leader>co", fzf.lsp_outgoing_calls, "[C]ode [O]utgoing calls")
    nmap("gO", fzf.lsp_document_symbols, "d[O]ocument symbols")
    nmap("<leader>ws", fzf.lsp_live_workspace_symbols, "[W]orkspace [S]ymbols")
    nmap("<leader>wd", fzf.diagnostics_workspace, "[W]orkspace [D]iagnostics")

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
        group = vim.api.nvim_create_augroup("lsp-detach", { clear = true }),
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
      vim.lsp.codelens.enable(true, { bufnr = bufnr })
    end

    if
      client
      and client:supports_method(
        vim.lsp.protocol.Methods.textDocument_inlayHint,
        event.buf
      )
    then
      nmap("<leader>th", function()
        vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled(event.buf))
      end, "[T]oggle Inlay [H]ints")
    end
  end,
})

require("conform").setup({
  formatters_by_ft = {
    awk = { "gawk" },
    bash = { "shfmt" },
    cmake = { "cmake_format" },
    css = { "prettier", "stylelint" },
    html = { "prettier" },
    javascript = { "prettier" },
    typescript = { "prettier" },
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

vim.keymap.set("", "<leader>f", function()
  require("conform").format({ async = true, lsp_fallback = true })
end, { desc = "[F]ormat buffer" })

local lint = require("lint")
lint.linters_by_ft = {
  css = { "stylelint" },
  dockerfile = { "hadolint" },
  json = { "jsonlint" },
  markdown = { "markdownlint" },
  makefile = { "checkmake" },
  yaml = { "yamllint", "yq" },
  ghaction = { "actionlint" },
  zsh = { "zsh" },
  ["*"] = { "codespell", "typos" },
}
vim.api.nvim_create_autocmd({ "BufReadPost", "BufWritePost" }, {
  group = vim.api.nvim_create_augroup("lint", { clear = true }),
  callback = function()
    if vim.opt_local.modifiable:get() then
      lint.try_lint()
    end
  end,
})

require("tiny-inline-diagnostic").setup({
  options = {
    show_source = {
      if_many = true,
    },
    set_arrow_to_diag_color = true,
    multilines = {
      enabled = true,
    },
    show_all_diags_on_cursorline = true,
    enable_on_select = true,
    break_line = {
      enabled = true,
    },
    severity = {
      vim.diagnostic.severity.ERROR,
      vim.diagnostic.severity.WARN,
      vim.diagnostic.severity.INFO,
      vim.diagnostic.severity.HINT,
    },
  },
})
