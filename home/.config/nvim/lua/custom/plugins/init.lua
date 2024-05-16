local map = require("mapper")

return {
  { "nvim-lua/plenary.nvim", lazy = true },
  { "tpope/vim-repeat",      event = "VeryLazy" },
  'tpope/vim-sleuth',
  {
    "numToStr/Comment.nvim",
    config = true,
  },
  {
    "tpope/vim-unimpaired",
    keys = { "]", "[", "yo" },
  },
  { "folke/which-key.nvim",   lazy = true },
  { "kylechui/nvim-surround", config = true },
  {
    "dstein64/vim-startuptime",
    cmd = "StartupTime",
  },
  "xiyaowong/nvim-cursorword",
  {
    "sainnhe/gruvbox-material",
    priority = 1000,
    config = function()
      vim.g.gruvbox_material_background = "hard"
      vim.g.gruvbox_material_enable_bold = 1
      vim.g.gruvbox_material_enable_italic = 1
      vim.g.gruvbox_material_better_performance = 1
      vim.g.gruvbox_material_palette = "original"

      vim.cmd([[ colorscheme  gruvbox-material]])
    end
  },
  {
    "aserowy/tmux.nvim",
    config = true,
  },
  {
    "Julian/vim-textobj-variable-segment",
    dependencies = { "kana/vim-textobj-user" },
  },
  {
    "norcalli/nvim-colorizer.lua",
    event = "BufRead",
    config = true
  },
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
  { 'akinsho/git-conflict.nvim', config = true },
  {
    "lukas-reineke/indent-blankline.nvim",
    config = function()
      local highlight = {
        "RainbowRed",
        "RainbowYellow",
        "RainbowBlue",
        "RainbowOrange",
        "RainbowGreen",
        "RainbowViolet",
        "RainbowCyan",
      }
      local hooks = require "ibl.hooks"
      -- create the highlight groups in the highlight setup hook, so they are reset
      -- every time the colorscheme changes
      hooks.register(hooks.type.HIGHLIGHT_SETUP, function()
        vim.api.nvim_set_hl(0, "RainbowRed", { fg = "#E06C75" })
        vim.api.nvim_set_hl(0, "RainbowYellow", { fg = "#E5C07B" })
        vim.api.nvim_set_hl(0, "RainbowBlue", { fg = "#61AFEF" })
        vim.api.nvim_set_hl(0, "RainbowOrange", { fg = "#D19A66" })
        vim.api.nvim_set_hl(0, "RainbowGreen", { fg = "#98C379" })
        vim.api.nvim_set_hl(0, "RainbowViolet", { fg = "#C678DD" })
        vim.api.nvim_set_hl(0, "RainbowCyan", { fg = "#56B6C2" })
      end)

      vim.g.rainbow_delimiters = { highlight = highlight }
      require("ibl").setup { scope = { highlight = highlight } }

      hooks.register(hooks.type.SCOPE_HIGHLIGHT,
        hooks.builtin.scope_highlight_from_extmark)
    end
  },
  {
    "monaqa/dial.nvim",
    config = function()
      map.n("]i", require("dial.map").inc_normal())
      map.n("[i", require("dial.map").dec_normal())
      map.v("]i", require("dial.map").inc_visual())
      map.v("[i", require("dial.map").dec_visual())
    end
  },
  {
    "iamcco/markdown-preview.nvim",
    cmd = { "MarkdownPreviewToggle", "MarkdownPreview", "MarkdownPreviewStop" },
    build = "cd app && yarn install",
    ft = { "markdown" },
  },
  "gpanders/editorconfig.nvim",
  {
    "kwkarlwang/bufresize.nvim",
    config = true
  },
  "kovetskiy/sxhkd-vim",
  "tmux-plugins/vim-tmux",
  "chrisbra/csv.vim",
  "martinda/Jenkinsfile-vim-syntax",
  "rhysd/vim-llvm",
  "MTDL9/vim-log-highlighting",
  "raimon49/requirements.txt.vim",
  "wgwoods/vim-systemd-syntax",
  {
    "NeogitOrg/neogit",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-telescope/telescope.nvim",
    },
    config = function()
      local neogit = require("neogit")
      neogit.setup({
        disable_commit_confirmation = true,
        kind = "split",
        console_timeout = 5000,
        auto_show_console = false,
      })
      map.n("<leader>ng", neogit.open)
    end,
  },
  {
    "ruifm/gitlinker.nvim",
    keys = {
      { "<leader>gy", function() require 'gitlinker'.get_buf_range_url("n") end },
      {
        "<leader>gy",
        function()
          require 'gitlinker'.get_buf_range_url("v")
        end,
        mode = "v"
      },
    },
    dependencies = {
      "nvim-lua/plenary.nvim",
    },
    config = function()
      require "gitlinker".setup({
        callbacks = {
          ["personal"] = function(url_data)
            url_data.host = "github.com"
            return require "gitlinker.hosts".get_github_type_url(url_data)
          end,
          ["work"] = function(url_data)
            url_data.host = "github.com"
            return require "gitlinker.hosts".get_github_type_url(url_data)
          end,
          ["git.strisemarx.com"] = function(url_data)
            local url = require "gitlinker.hosts".get_base_https_url(url_data)
            url = url .. "/tree/" .. url_data.file .. "?id=" .. url_data.rev
            if url_data.lstart then
              url = url .. "#n" .. url_data.lstart
            end
            return url
          end
        },
      })
    end,
  },
  {
    "lewis6991/gitsigns.nvim",
    event = "BufRead",
    opts = {
      signs = {
        change = { show_count = true },
        delete = { show_count = true },
        topdelete = { show_count = true },
        changedelete = { show_count = true },
      },
      numhl = true,
      _extmark_signs = true,
      _threaded_diff = true,
      _signs_staged_enable = true,
      on_attach = function(bufnr)
        local gs = package.loaded.gitsigns

        -- Navigation
        map.n(']c', function()
          if vim.wo.diff then return ']c' end
          vim.schedule(function() gs.next_hunk() end)
          return '<Ignore>'
        end, { expr = true }, bufnr)

        map.n('[c', function()
          if vim.wo.diff then return '[c' end
          vim.schedule(function() gs.prev_hunk() end)
          return '<Ignore>'
        end, { expr = true }, bufnr)

        -- Actions
        map.nvcmd('<leader>hs', "Gitsigns stage_hunk", nil, bufnr)
        map.nvcmd('<leader>hr', "Gitsigns reset_hunk", nil, bufnr)
        map.n('<leader>hS', gs.stage_buffer, nil, bufnr)
        map.n('<leader>hu', gs.undo_stage_hunk, nil, bufnr)
        map.n('<leader>hR', gs.reset_buffer, nil, bufnr)
        map.n('<leader>hp', gs.preview_hunk, nil, bufnr)
        map.n('<leader>hb', function() gs.blame_line { full = true } end, nil,
          bufnr)
        map.n('<leader>tb', gs.toggle_current_line_blame, nil, bufnr)
        map.n('<leader>hd', gs.diffthis, nil, bufnr)
        map.n('<leader>hD', function() gs.diffthis('~') end, nil, bufnr)
        map.n('<leader>hc', gs.change_base, nil, bufnr)
        map.n('<leader>hC', function() gs.change_base('~') end, nil, bufnr)
        map.n('<leader>td', gs.toggle_deleted, nil, bufnr)
        map.n('<leader>tw', gs.toggle_word_diff, nil, bufnr)
        map.n('<leader>tl', gs.toggle_linehl, nil, bufnr)

        -- Text object
        map.map({ 'o', 'x' }, 'ih', ':<C-U>Gitsigns select_hunk<CR>', nil, bufnr)
      end
    },
    dependencies = {
      "nvim-lua/plenary.nvim",
    },
  },
  {
    "nvim-telescope/telescope.nvim",
    config = function()
      local actions = require("telescope.actions")
      require("telescope").setup({
        defaults = {
          sorting_strategy = "ascending",
          layout_config = {
            prompt_position = "top",
          },
          scroll_strategy = "cycle",
          selection_strategy = "follow",
          color_devicons = false,
          mappings = {
            i = {
              ["<c-j>"] = actions.move_selection_next,
              ["<c-k>"] = actions.move_selection_previous,
            },
          },
          extensions = {
            fzf = {
              fuzzy = true,                   -- false will only do exact matching
              override_generic_sorter = true, -- override the generic sorter
              override_file_sorter = true,    -- override the file sorter
              case_mode = "smart_case",       -- or "ignore_case" or "respect_case"
            },
            ["ui-select"] = {
              require("telescope.themes").get_dropdown({
                -- even more opts
              }),
            },
          },
        },
      })
      require("telescope").load_extension("fzf")
      require("telescope").load_extension("ui-select")

      local b = require("telescope.builtin")

      map.n("<localleader>p", b.planets)
      map.n("<localleader>B", b.builtin)
      map.n("<localleader>/", b.live_grep)
      map.n("<localleader>?", b.grep_string)
      map.n("<localleader>f", function()
        b.find_files({
          find_command = {
            "fd",
            "--type",
            "file",
            "--follow",
            "--hidden",
            "--exclude",
            ".git",
          },
        })
      end)
      map.n("<localleader>b", function()
        b.buffers({ sort_lastused = true, initial_mode = "normal" })
      end)

      map.n("<localleader>t", b.treesitter)

      map.n("<localleader>c", b.commands)
      map.n("<localleader>h", b.help_tags)
      map.n("<localleader>m", b.man_pages)
      map.n("<localleader>k", b.keymaps)
      map.n("<localleader>Q", function()
        b.quickfix({ initial_mode = "normal" })
      end)
      map.n("<localleader>L", function()
        b.loclist({ initial_mode = "normal" })
      end)
      map.n("<localleader>R", function()
        b.registers({ initial_mode = "normal" })
      end)
      map.n("<localleader>A", b.autocommands)

      map.n("gd", function()
        b.lsp_definitions({ initial_mode = "normal" })
      end)
      map.n("gvd", function()
        b.lsp_definitions({ initial_mode = "normal", jump_type = "vsplit" })
      end)
      map.n("gxd", function()
        b.lsp_definitions({ initial_mode = "normal", jump_type = "split" })
      end)
      map.n("gtd", function()
        b.lsp_definitions({ initial_mode = "normal", jump_type = "tab" })
      end)
      map.n("gi", function()
        b.lsp_implementations({ initial_mode = "normal" })
      end)
      map.n("gvi", function()
        b.lsp_implementations({ initial_mode = "normal", jump_type = "vsplit" })
      end)
      map.n("gxi", function()
        b.lsp_implementations({ initial_mode = "normal", jump_type = "split" })
      end)
      map.n("gti", function()
        b.lsp_implementations({ initial_mode = "normal", jump_type = "tab" })
      end)
      map.n("go", b.lsp_document_symbols)
      map.n("gS", b.lsp_dynamic_workspace_symbols)
      map.n("ge", function()
        b.lsp_document_diagnostics({ initial_mode = "normal" })
      end)
      map.n("gE", function()
        b.lsp_workspace_diagnostics({ initial_mode = "normal" })
      end)
      map.n("gr", function()
        b.lsp_references({ initial_mode = "normal" })
      end)
      map.n("gic", function()
        b.lsp_incoming_calls({ initial_mode = "normal" })
      end)
      map.n("goc", function()
        b.lsp_outgoing_calls({ initial_mode = "normal" })
      end)
    end,
    dependencies = {
      "nvim-lua/plenary.nvim",
      {
        "nvim-telescope/telescope-fzf-native.nvim",
        build = "make",
      },
      "nvim-telescope/telescope-ui-select.nvim",
    },
  },
  {
    "mfussenegger/nvim-dap",
    config = function()
      local dap = require("dap")

      dap.defaults.fallback.force_external_terminal = true
      dap.defaults.fallback.external_terminal = {
        command = "/usr/bin/st",
        args = { "-e" },
      }

      dap.defaults.fallback.terminal_win_cmd = "50vsplit new"

      local function get_env_vars()
        local variables = {}
        for k, v in pairs(vim.fn.environ()) do
          table.insert(variables, string.format("%s=%s", k, v))
        end
        return variables
      end

      dap.adapters.lldb = {
        type = "executable",
        command = "/usr/bin/lldb-vscode",
        name = "lldb",
      }

      local function str_split(inputstr, sep)
        sep = sep or "%s"
        local t = {}
        for str in inputstr:gmatch("([^" .. sep .. "]+)") do
          table.insert(t, str)
        end
        return t
      end

      local _cmd = nil

      local function get_cmd()
        if _cmd then
          return _cmd
        end
        local clipboard_cmd = vim.fn.getreg("+")
        _cmd = vim.fn.input({
          prompt = "Command to execute: ",
          default = clipboard_cmd
        })
        return _cmd
      end

      local function get_program()
        return str_split(get_cmd())[1]
      end

      local function get_args()
        local argv = str_split(get_cmd())
        local args = {}

        if #argv < 2 then
          return {}
        end

        for i = 2, #argv do
          args[#args + 1] = argv[i]
        end

        return args
      end

      dap.configurations.cpp = {
        {
          name = "Launch",
          type = "lldb",
          request = "launch",
          cwd = "${workspaceFolder}",
          program = get_program,
          stopOnEntry = true,
          args = get_args,
          env = get_env_vars,
          runInTerminal = true,
        },
        {
          -- If you get an "Operation not permitted" error using this, try disabling YAMA:
          --  echo 0 | sudo tee /proc/sys/kernel/yama/ptrace_scope
          name = "Attach to process",
          type = "lldb",
          request = "attach",
          pid = require('dap.utils').pick_process,
        },
      }

      dap.configurations.c = dap.configurations.cpp
      dap.configurations.rust = dap.configurations.cpp

      local get_python_path = function()
        local venv_path = os.getenv("VIRTUAL_ENV")
        if venv_path then
          return venv_path .. "/bin/python"
        end
        return "/usr/bin/python"
      end

      require("dap-python").setup(get_python_path())

      dap.adapters.nlua = function(callback, config)
        callback({ type = "server", host = config.host, port = config.port })
      end

      dap.configurations.lua = {
        {
          type = "nlua",
          request = "attach",
          name = "Attach to running Neovim instance",
          host = function()
            local value = vim.fn.input("Host [127.0.0.1]: ")
            if value ~= "" then
              return value
            end
            return "127.0.0.1"
          end,
          port = function()
            local val = tonumber(vim.fn.input("Port: "))
            assert(val, "Please provide a port number")
            return val
          end,
        },
      }

      dap.repl.commands = vim.tbl_extend("force", dap.repl.commands, {
        continue = { "continue", "c" },
        next_ = { "next", "n" },
        back = { "back", "b" },
        reverse_continue = { "reverse-continue", "rc" },
        into = { "into" },
        into_target = { "into_target" },
        out = { "out" },
        scopes = { "scopes" },
        threads = { "threads" },
        frames = { "frames" },
        exit = { "exit", "quit", "q" },
        up = { "up" },
        down = { "down" },
        goto_ = { "goto" },
        capabilities = { "capabilities", "cap" },
        -- add your own commands
        custom_commands = {
          ["echo"] = function(text)
            dap.repl.append(text)
          end,
        },
      })

      map.n("<F4>", dap.close)
      map.n("<F5>", dap.continue)
      map.n("<F10>", dap.step_over)
      map.n("<F11>", dap.step_into)
      map.n("<F12>", dap.step_out)
      map.n("<leader>b", dap.toggle_breakpoint)
      map.n("<leader>B", function()
        dap.set_breakpoint(vim.fn.input("Breakpoint condition: "))
      end)
      map.n("<leader>lp", function()
        dap.set_breakpoint(nil, nil, vim.fn.input("Log point message: "))
      end)
      map.n("<leader>dr", dap.repl.open)
      map.n("<leader>dl", dap.run_last)
      map.n("<F2>", dap.list_breakpoints)

      local dapui = require("dapui")
      dap.listeners.after.event_initialized["dapui_config"] = function()
        dapui.open()
      end
      dap.listeners.before.event_terminated["dapui_config"] = function()
        dapui.close()
      end
      dap.listeners.before.event_exited["dapui_config"] = function()
        dapui.close()
      end
      map.n("<leader>du", dapui.toggle)
      map.v("<leader>de", dapui.eval)
    end,
    dependencies = {
      {
        "rcarriga/nvim-dap-ui",
        dependencies = "nvim-neotest/nvim-nio",
        opts = {
          icons = { expanded = "-", collapsed = "+", current_frame = "*" },
          controls = { enabled = false },
          layouts = {
            {
              elements = {
                -- Elements can be strings or table with id and size keys.
                "scopes",
                "breakpoints",
                "stacks",
                "watches",
              },
              size = 40,
              position = "left",
            },
            {
              elements = {
                "repl",
              },
              size = 0.25, -- 25% of total lines
              position = "bottom",
            },
          },
        },
      },
      {
        "mfussenegger/nvim-dap-python",
        keys = {
          { "gm", function()
            require("dap-python").test_method()
          end },
          {
            "g<cr>",
            function()
              require("dap-python").debug_selection()
            end,
            mode = "v"
          },
        },
      },
      "jbyuki/one-small-step-for-vimkind",
      {
        "theHamsta/nvim-dap-virtual-text",
        config = true,
        dependencies = { "nvim-treesitter/nvim-treesitter" }
      }
    },
  },
  {
    'nvim-treesitter/nvim-treesitter',
    dependencies = {
      'nvim-treesitter/nvim-treesitter-textobjects',
      "nvim-treesitter/nvim-treesitter-refactor",
      "RRethy/nvim-treesitter-textsubjects",
      "theHamsta/nvim-treesitter-pairs",
      "RRethy/nvim-treesitter-endwise",
    },
    build = ":TSUpdate",
    config = function()
      require("nvim-treesitter.configs").setup({
        ensure_installed = {
          "bash",
          "c",
          "cmake",
          "comment",
          "cpp",
          "css",
          "cuda",
          "diff",
          "dockerfile",
          "fortran",
          "git_rebase",
          "gitattributes",
          "gitcommit",
          "gitignore",
          "go",
          "html",
          "javascript",
          "jsdoc",
          "json",
          "llvm",
          "lua",
          "make",
          "markdown",
          "markdown_inline",
          "ninja",
          "python",
          "regex",
          "rust",
          "sql",
          "todotxt",
          "toml",
          "typescript",
          "vim",
          "vimdoc",
          "yaml"
        },
        -- ignore_install = { "phpdoc" },
        highlight = {
          enable = true, -- false will disable the whole extension
          additional_vim_regex_highlighting = false,
        },
        incremental_selection = {
          enable = true,
          keymaps = {
            init_selection = "gnn",
            node_incremental = "grn",
            scope_incremental = "grc",
            node_decremental = "grm",
          },
        },
        indent = { enable = true },
        refactor = {
          highlight_definitions = { enable = true },
          highlight_current_scope = { enable = true },
          smart_rename = { enable = true, keymaps = { smart_rename = "grr" } },
          navigation = {
            enable = true,
            keymaps = {
              goto_definition = "gnd",
              list_definitions = "gnD",
              list_definitions_toc = "gO",
              goto_next_usage = "<a-*>",
              goto_previous_usage = "<a-#>",
            },
          },
        },
        textobjects = {
          select = {
            enable = true,
            -- Automatically jump forward to textobj, similar to targets.vim
            lookahead = true,
            keymaps = {
              -- You can use the capture groups defined in textobjects.scm
              ["af"] = "@function.outer",
              ["if"] = "@function.inner",
              ["ac"] = "@class.outer",
              ["ic"] = "@class.inner",
            },
          },
          swap = {
            enable = true,
            swap_next = { ["<leader>a"] = "@parameter.inner" },
            swap_previous = { ["<leader>A"] = "@parameter.inner" },
          },
          move = {
            enable = true,
            set_jumps = true, -- whether to set jumps in the jumplist
            goto_next_start = {
              ["]m"] = "@function.outer",
              ["]]"] = "@class.outer",
            },
            goto_next_end = {
              ["]M"] = "@function.outer",
              ["]["] = "@class.outer",
            },
            goto_previous_start = {
              ["[m"] = "@function.outer",
              ["[["] = "@class.outer",
            },
            goto_previous_end = {
              ["[M"] = "@function.outer",
              ["[]"] = "@class.outer",
            },
          },
          lsp_interop = {
            enable = true,
            peek_definition_code = {
              ["df"] = "@function.outer",
              ["dF"] = "@class.outer",
            },
          },
        },
        matchup = {
          enable = true,
        },
        pairs = {
          enable = true,
          goto_right_end = false,
          keymaps = { goto_partner = "%" },
        },
        textsubjects = {
          enable = true,
          keymaps = { ["."] = "textsubjects-smart", [";"] = "textsubjects-big" },
        },
        tree_docs = {
          enable = true,
        },
        endwise = {
          enable = true,
        },
      })
    end
  },
  {
    "hrsh7th/nvim-cmp",
    event = "InsertEnter",
    config = function()
      local cmp = require("cmp")

      local has_words_before = function()
        local line, col = unpack(vim.api.nvim_win_get_cursor(0))
        return col ~= 0
            and vim.api.nvim_buf_get_lines(0, line - 1, line, true)[1]
            :sub(col, col)
            :match("%s")
            == nil
      end

      local luasnip = require("luasnip")

      cmp.setup({
        snippet = {
          expand = function(args)
            require("luasnip").lsp_expand(args.body)
          end,
        },
        mapping = {
          ["<Tab>"] = cmp.mapping(function(fallback)
            if cmp.visible() then
              cmp.select_next_item()
            elseif luasnip.expand_or_jumpable() then
              luasnip.expand_or_jump()
            elseif has_words_before() then
              cmp.complete()
            else
              fallback()
            end
          end, {
            "i",
            "s",
          }),
          ["<S-Tab>"] = cmp.mapping(function(fallback)
            if cmp.visible() then
              cmp.select_prev_item()
            elseif luasnip.jumpable(-1) then
              luasnip.jump(-1)
            else
              fallback()
            end
          end, {
            "i",
            "s",
          }),
          ["<CR>"] = cmp.mapping.confirm({
            behavior = cmp.ConfirmBehavior.Replace,
            select = true,
          }),
        },
        formatting = {
          format = function(entry, vim_item)
            -- set a name for each source
            vim_item.menu = ({
              path = "[Path]",
              nvim_lsp = "[LSP]",
              luasnip = "[LuaSnip]",
              dap = "[dap]",
            })[entry.source.name]
            return vim_item
          end,
        },
        sources = {
          { name = "nvim_lsp" },
          { name = "luasnip" },
          { name = "path" },
          { name = "nvim_lsp_signature_help" },
        },
      })

      require "cmp".setup.filetype(
        { "dap-repl", "dapui_watches", "dapui_hover" }, {
          sources = {
            { name = "dap" },
          },
        })
    end,
    dependencies = {
      "hrsh7th/cmp-nvim-lsp",
      "hrsh7th/cmp-path",
      "hrsh7th/cmp-nvim-lsp-signature-help",
      "rcarriga/cmp-dap",
      {
        "saadparwaiz1/cmp_luasnip",
        dependencies = {
          {
            "L3MON4D3/LuaSnip",
            event = "InsertCharPre",
            keys = {
              { "<c-j>", function() require "luasnip".jump(1) end,  mode = "i" },
              { "<c-k>", function() require "luasnip".jump(-1) end, mode = "i" },
            },
            config = function()
              require("luasnip/loaders/from_vscode").lazy_load()
            end,
            dependencies = {
              "kitagry/vs-snippets",
              "rafamadriz/friendly-snippets",
              "kkonghao/snippet-dog",
            },
          }
        },
      },
    },
  },
  {
    'neovim/nvim-lspconfig',
    config = function()
      local lspconfig = require("lspconfig")
      -- Enable (broadcasting) snippet capability for completion
      local capabilities = vim.lsp.protocol.make_client_capabilities()
      capabilities.textDocument.completion.completionItem.snippetSupport = true
      capabilities.workspace.didChangeWatchedFiles.dynamicRegistration = true
      capabilities = require("cmp_nvim_lsp").default_capabilities(capabilities)

      lspconfig.util.default_config = vim.tbl_extend(
        "force",
        lspconfig.util.default_config,
        {
          on_attach = require "cfg.lsp".on_attach_wrapper,
          capabilities = capabilities,
          flags = {
            debounce_text_changes = 150,
          },
        }
      )

      local function switch_source_header_splitcmd(bufnr, splitcmd)
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

      local servers = {
        bashls = {},
        dockerls = {},
        fortls = {},
        lua_ls = {
          on_attach = function(client, bufnr)
            require("cfg.lsp").on_attach_wrapper(
              client,
              bufnr,
              { auto_format = true }
            )
          end,
          settings = {
            Lua = {
              completion = {
                callSnippet = "Both",
                displayContext = 1,
              },
              hint = {
                enable = true,
              }
            }
          },
        },
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
                switch_source_header_splitcmd(0, "edit")
              end,
              description = "Open source/header in current buffer",
            },
            ClangdSwitchSourceHeaderVSplit = {
              function()
                switch_source_header_splitcmd(0, "vsplit")
              end,
              description = "Open source/header in a new vsplit",
            },
            ClangdSwitchSourceHeaderSplit = {
              function()
                switch_source_header_splitcmd(0, "split")
              end,
              description = "Open source/header in a new split",
            },
            ClangdSwitchSourceHeaderTab = {
              function()
                switch_source_header_splitcmd(0, "tabedit")
              end,
              description = "Open source/header in a new tab",
            },
          },
          on_attach = function(client, bufnr)
            require("cfg.lsp").on_attach_wrapper(client, bufnr)
            local cmpconfig = require("cmp.config")
            local compare = require("cmp.config.compare")
            cmpconfig.set_buffer({
              sorting = {
                comparators = {
                  compare.offset,
                  compare.exact,
                  -- compare.scopes,
                  require("clangd_extensions.cmp_scores"),
                  compare.recently_used,
                  compare.locality,
                  compare.kind,
                  compare.sort_text,
                  compare.length,
                  compare.order,
                },
              },
            }, bufnr)
            vim.api.nvim_create_augroup("clang-format", {})
            vim.api.nvim_create_autocmd("BufWritePre", {
              group = "clang-format",
              buffer = bufnr,
              callback = function()
                if vim.fn.expand('%:p:h'):find("test") then
                  return
                end
                require("cfg.utils").format_hunks({
                  bufnr = bufnr,
                  async = false,
                  id = client.id
                })
              end,
            })
            map.ncmd("gH", "ClangdSwitchSourceHeader")
            map.ncmd("gvH", "ClangdSwitchSourceHeaderVSplit")
            map.ncmd("gxH", "ClangdSwitchSourceHeaderSplit")
            map.ncmd("gtH", "ClangdSwitchSourceHeaderSplit")

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
    end,
    dependencies = {
      "hrsh7th/cmp-nvim-lsp",
      "ray-x/lsp_signature.nvim",
      "jubnzv/virtual-types.nvim",
      { 'folke/neodev.nvim',            opts = {} },
      { "lvimuser/lsp-inlayhints.nvim", config = true },
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
    'mrcjkb/rustaceanvim',
    config = function()
      vim.g.rustaceanvim = {
        server = {
          on_attach = function(client, bufnr)
            require("cfg.lsp").on_attach_wrapper(
              client,
              bufnr,
              { auto_format = true }
            )
          end,
        },
      }
    end,
    ft = { 'rust' },
  },
  {
    'nvim-lualine/lualine.nvim',
    opts = {
      options = {
        icons_enabled = false,
        theme = 'gruvbox_dark',
        component_separators = '',
        section_separators = '|',
      },
      sections = {
        lualine_a = { 'filetype', { 'filename', path = 1 } },
        lualine_b = { '%l/%L:%c:%o' },
        lualine_c = { 'diff' },
        lualine_x = { 'searchcount, selectioncount' },
        lualine_y = {},
        lualine_z = { 'diagnostics' }
      },
      inactive_sections = {
        lualine_a = { 'filename' },
        lualine_b = {},
        lualine_c = {},
        lualine_x = {},
        lualine_y = {},
        lualine_z = {}
      },
    },
  },
  {
    "nvimtools/none-ls.nvim",
    config = function()
      local nls = require("null-ls")
      nls.setup({
        on_attach = function(client, bufnr)
          require("cfg.lsp").on_attach_wrapper(
            client,
            bufnr,
            { auto_format = true }
          )
        end,
        sources = {
          nls.builtins.formatting.black,
          nls.builtins.diagnostics.hadolint,
        }
      })
    end,
  },
  "https://gitlab.com/HiPhish/rainbow-delimiters.nvim",
}
