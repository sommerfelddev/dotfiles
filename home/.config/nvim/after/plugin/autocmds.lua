local function augroup(name)
  return vim.api.nvim_create_augroup(name, { clear = true })
end

local autocmd = vim.api.nvim_create_autocmd

-- Check if we need to reload the file when it changed
autocmd({ "FocusGained", "TermClose", "TermLeave" }, {
  group = augroup("checktime"),
  callback = function()
    if vim.o.buftype ~= "nofile" then
      vim.cmd("checktime")
    end
  end,
})

-- Highlight on yank
autocmd("TextYankPost", {
  group = augroup("highlight_yank"),
  callback = vim.hl.on_yank,
})

-- go to last loc when opening a buffer
autocmd("BufReadPost", {
  group = augroup("last_loc"),
  callback = function(event)
    local exclude = { "gitcommit" }
    local buf = event.buf
    if
      vim.tbl_contains(exclude, vim.bo[buf].filetype) or vim.b[buf].last_loc
    then
      return
    end
    vim.b[buf].last_loc = true
    local mark = vim.api.nvim_buf_get_mark(buf, '"')
    local lcount = vim.api.nvim_buf_line_count(buf)
    if mark[1] > 0 and mark[1] <= lcount then
      pcall(vim.api.nvim_win_set_cursor, 0, mark)
    end
  end,
})

-- close some filetypes with <q>
autocmd("FileType", {
  group = augroup("close_with_q"),
  pattern = {
    "PlenaryTestPopup",
    "checkhealth",
    "dbout",
    "gitsigns-blame",
    "grug-far",
    "help",
    "lspinfo",
    "neotest-output",
    "neotest-output-panel",
    "neotest-summary",
    "notify",
    "qf",
    "spectre_panel",
    "startuptime",
    "tsplayground",
  },
  callback = function(event)
    vim.bo[event.buf].buflisted = false
    vim.schedule(function()
      vim.keymap.set("n", "q", function()
        vim.cmd("close")
        pcall(vim.api.nvim_buf_delete, event.buf, { force = true })
      end, {
        buffer = event.buf,
        silent = true,
        desc = "Quit buffer",
      })
    end)
  end,
})

-- make it easier to close man-files when opened inline
autocmd("FileType", {
  group = augroup("man_unlisted"),
  pattern = { "man" },
  callback = function(event)
    vim.bo[event.buf].buflisted = false
  end,
})

-- Auto create dir when saving a file, in case some intermediate directory does not exist
autocmd({ "BufWritePre" }, {
  group = augroup("auto_create_dir"),
  callback = function(event)
    if event.match:match("^%w%w+:[\\/][\\/]") then
      return
    end
    local file = vim.uv.fs_realpath(event.match) or event.match
    vim.fn.mkdir(vim.fn.fnamemodify(file, ":p:h"), "p")
  end,
})

autocmd("BufWritePost", {
  group = augroup("bspwm"),
  pattern = "*bspwmrc",
  command = "!bspc wm --restart",
})
autocmd("BufWritePost", {
  group = augroup("polybar"),
  pattern = "*/polybar/config",
  command = "!polybar-msg cmd restart",
})
autocmd("BufWritePost", {
  group = augroup("xdg-user-dirs"),
  pattern = "user-dirs.dirs,user-dirs.locale",
  command = "!xdg-user-dirs-update",
})
autocmd("BufWritePost", {
  group = augroup("dunst"),
  pattern = "dunstrc",
  command = "!killall -SIGUSR2 dunst",
})
autocmd("BufWritePost", {
  group = augroup("fc-cache"),
  pattern = "fonts.conf",
  command = "!fc-cache",
})

autocmd("LspAttach", {
  group = augroup("lsp-attach"),
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

    -- fzf-lua LSP navigation
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
    nmap("<leader>ws", fzf.lsp_live_workspace_symbols, "[W]orkspace [S]ymbols")
    nmap("<leader>wd", fzf.diagnostics_workspace, "[W]orkspace [D]iagnostics")

    -- Highlight references under cursor
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
      vim.api.nvim_create_autocmd(
        { "CursorHold", "CursorHoldI", "InsertLeave" },
        {
          buffer = bufnr,
          group = vim.api.nvim_create_augroup("codelens", { clear = true }),
          callback = vim.lsp.codelens.refresh,
        }
      )
    end

    -- Toggle inlay hints
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

autocmd("FileType", {
  group = augroup("treesitter_start"),
  pattern = { "*" },
  callback = function()
    if pcall(vim.treesitter.start) then
      vim.wo.foldexpr = "v:lua.vim.treesitter.foldexpr()"
      vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
    end
  end,
})
