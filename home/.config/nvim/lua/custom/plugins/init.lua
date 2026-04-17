return {
  { "nvim-lua/plenary.nvim", branch = "master", lazy = true },
  {
    "nmac427/guess-indent.nvim",
    event = "BufRead",
    opts = {},
  },
  {
    "kylechui/nvim-surround",
    event = "VeryLazy",
    opts = {},
  },
  {
    "chrisgrieser/nvim-various-textobjs",
    event = "VeryLazy",
    opts = {
      keymaps = {
        useDefaults = true,
      },
    },
  },
  {
    "monaqa/dial.nvim",
    keys = {
      {
        "]i",
        function()
          require("dial.map").inc_normal()
        end,
        expr = true,
        desc = "Increment",
      },
      {
        "[i",
        function()
          require("dial.map").dec_normal()
        end,
        expr = true,
        desc = "Decrement",
      },
      {
        "]i",
        function()
          require("dial.map").inc_visual()
        end,
        expr = true,
        mode = "v",
        desc = "Increment",
      },
      {
        "[i",
        function()
          require("dial.map").dec_visual()
        end,
        expr = true,
        mode = "v",
        desc = "Decrement",
      },
    },
  },
  {
    "iamcco/markdown-preview.nvim",
    cmd = { "MarkdownPreviewToggle", "MarkdownPreview", "MarkdownPreviewStop" },
    build = "cd app && yarn install",
    ft = "markdown",
  },
  {
    "rmagatti/auto-session",
    lazy = false,
    opts = function()
      -- Convert the cwd to a simple file name
      local function get_cwd_as_name()
        local dir = vim.fn.getcwd(0)
        return dir:gsub("[^A-Za-z0-9]", "_")
      end
      local overseer = require("overseer")
      return {
        use_git_branch = true,
        pre_save_cmds = {
          function()
            overseer.save_task_bundle(
              get_cwd_as_name(),
              -- Passing nil will use config.opts.save_task_opts. You can call list_tasks() explicitly and
              -- pass in the results if you want to save specific tasks.
              nil,
              { on_conflict = "overwrite" } -- Overwrite existing bundle, if any
            )
          end,
        },
        -- Optionally get rid of all previous tasks when restoring a session
        pre_restore_cmds = {
          function()
            for _, task in ipairs(overseer.list_tasks({})) do
              task:dispose(true)
            end
          end,
        },
        post_restore_cmds = {
          function()
            overseer.load_task_bundle(
              get_cwd_as_name(),
              { ignore_missing = true, autostart = false }
            )
          end,
        },
        save_extra_data = function(_)
          local ok, breakpoints = pcall(require, "dap.breakpoints")
          if not ok or not breakpoints then
            return
          end

          local bps = {}
          local breakpoints_by_buf = breakpoints.get()
          for buf, buf_bps in pairs(breakpoints_by_buf) do
            bps[vim.api.nvim_buf_get_name(buf)] = buf_bps
          end
          if vim.tbl_isempty(bps) then
            return
          end
          local extra_data = {
            breakpoints = bps,
          }
          return vim.fn.json_encode(extra_data)
        end,

        restore_extra_data = function(_, extra_data)
          local json = vim.fn.json_decode(extra_data)

          if json.breakpoints then
            local ok, breakpoints = pcall(require, "dap.breakpoints")

            if not ok or not breakpoints then
              return
            end
            vim.notify("restoring breakpoints")
            for buf_name, buf_bps in pairs(json.breakpoints) do
              for _, bp in pairs(buf_bps) do
                local line = bp.line
                local opts = {
                  condition = bp.condition,
                  log_message = bp.logMessage,
                  hit_condition = bp.hitCondition,
                }
                breakpoints.set(opts, vim.fn.bufnr(buf_name), line)
              end
            end
          end
        end,
        suppressed_dirs = { "~/", "/" },
      }
    end,
  },
  {
    "aserowy/tmux.nvim",
    event = "VeryLazy",
    opts = {
      resize = {
        enable_default_keybindings = false,
      },
    },
  },
  {
    "stevearc/overseer.nvim",
    version = "v1.6.0",
    keys = {
      {
        "<leader>to",
        function()
          require("overseer").toggle()
        end,
        desc = "[T]oggle [O]verseer",
      },
      {
        "<leader>ob",
        function()
          require("overseer").run_template({
            name = "just build",
            prompt = "never",
          })
        end,
        desc = "[O]verseer [B]uild",
      },
      {
        "<leader>oB",
        function()
          require("overseer").run_template({
            name = "just build",
          })
        end,
        desc = "[O]verseer [B]uild",
      },
      {
        "<leader>ot",
        function()
          require("overseer").run_template({
            name = "just test",
            prompt = "never",
          })
        end,
        desc = "[O]verseer [J]ust [T]est",
      },
      {
        "<leader>oT",
        function()
          require("overseer").run_template({
            name = "just test",
          })
        end,
        desc = "[O]verseer [J]ust [T]est",
      },
      {
        "<leader>of",
        function()
          require("overseer").run_template({
            name = "just test",
            prompt = "never",
            params = { target = vim.fn.expand("%") },
          })
        end,
        desc = "[O]verseer test [F]ile",
      },
      {
        "<leader>oF",
        function()
          require("overseer").run_template({
            name = "just test",
            params = { target = vim.fn.expand("%") },
          })
        end,
        desc = "[O]verseer test [F]ile",
      },
      {
        "<leader>od",
        function()
          require("overseer").run_template({
            name = "just debug=true test",
            prompt = "never",
            params = { target = vim.fn.expand("%") },
          })
        end,
        desc = "[O]verseer [d]ebug test file",
      },
      {
        "<leader>oD",
        function()
          require("overseer").run_template({
            name = "just debug=true test",
            params = { target = vim.fn.expand("%") },
          })
        end,
        desc = "[O]verseer [D]ebug test file",
      },
      {
        "<leader>oa",
        function()
          require("overseer").run_template({
            name = "just test_autofix",
            prompt = "never",
            params = { target = vim.fn.expand("%") },
          })
        end,
        desc = "[O]verseer [A]utofix",
      },
      {
        "<leader>or",
        function()
          require("overseer").run_template()
        end,
        desc = "[O]verseer [R]un",
      },
      {
        "<leader>os",
        function()
          require("overseer").run_template({ name = "shell" })
        end,
        desc = "[O]verseer [S]hell",
      },
      {
        "<leader>ol",
        function()
          local tasks = require("overseer").list_tasks({ recent_first = true })
          if vim.tbl_isempty(tasks) then
            vim.notify("No tasks found", vim.log.levels.WARN)
          else
            require("overseer").run_action(tasks[1], "restart")
          end
        end,
        desc = "[O]verseer run [L]ast",
      },
    },
    config = function()
      local overseer = require("overseer")
      overseer.setup({})
      overseer.add_template_hook({ name = ".*" }, function(task_defn, util)
        util.add_component(task_defn, {
          "open_output",
          on_start = "never",
          on_complete = "failure",
          direction = "vertical",
        })
      end)
    end,
  },
  {
    "ThePrimeagen/refactoring.nvim",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-treesitter/nvim-treesitter",
    },
    keys = {
      {
        "<leader>re",
        function()
          require("refactoring").refactor("Extract Function")
        end,
        mode = "x",
        desc = "[R]efactor [E]xtract function",
      },
      {
        "<leader>rf",
        function()
          require("refactoring").refactor("Extract Function To File")
        end,
        mode = "x",
        desc = "[R]efactor extract function to [F]ile",
      },
      {
        "<leader>rv",
        function()
          require("refactoring").refactor("Extract Variable")
        end,
        mode = "x",
        desc = "[R]efactor extract [V]ariable",
      },
      {
        "<leader>rI",
        function()
          require("refactoring").refactor("Inline Function")
        end,
        desc = "[R]efactor [I]nline function",
      },
      {
        "<leader>ri",
        function()
          require("refactoring").refactor("Inline Variable")
        end,
        mode = { "x", "n" },
        desc = "[R]efactor [I]nline variable",
      },
      {
        "<leader>rb",
        function()
          require("refactoring").refactor("Extract Block")
        end,
        desc = "[R]efactor extract [B]lock",
      },
      {
        "<leader>rB",
        function()
          require("refactoring").refactor("Extract Block To File")
        end,
        desc = "[R]efactor extract [B]lock to file",
      },
      {
        "<leader>rp",
        function()
          require("refactoring").debug.printf({})
        end,
        desc = "[R]efactor [P]rint",
      },

      {
        "<leader>rV",
        function()
          require("refactoring").debug.print_var({})
        end,
        mode = { "x", "n" },
        desc = "[R]efactor [P]rint [V]ariable",
      },
      {
        "<leader>rc",
        function()
          require("refactoring").debug.cleanup({})
        end,
        desc = "[R]efactor [C]leanup",
      },
    },
    opts = {},
  },
  {
    "folke/which-key.nvim",
    event = "VeryLazy",
    opts = {
      spec = {
        { "g", group = "[G]oto" },
        { "yo", group = "Toggle options" },
        { "]", group = "Navigate to next" },
        { "[", group = "Navigate to previous" },
        { "<leader>c", group = "[C]ode", mode = { "n", "x" } },
        { "<leader>d", group = "[D]ocument" },
        { "<leader>g", group = "[G]it" },
        { "<leader>h", group = "Git [H]unk", mode = { "n", "v" } },
        { "<leader>n", group = "[N]eotest" },
        { "<leader>o", group = "[O]verseer" },
        { "<leader>r", group = "[R]efactor" },
        { "<leader>s", group = "[S]earch" },
        { "<leader>w", group = "[W]orkspace" },
        { "<leader>t", group = "[T]oggle" },
      },
    },
    keys = {
      {
        "<leader>?",
        function()
          require("which-key").show({ global = false })
        end,
        desc = "Buffer Local Keymaps (which-key)",
      },
    },
  },
  {
    "stevearc/quicker.nvim",
    event = "FileType qf",
    keys = {
      {
        "<leader>tq",
        function()
          require("quicker").toggle()
        end,
        desc = "[T]oggle [Q]uickfix",
      },
      {
        "<leader>tl",
        function()
          require("quicker").toggle({ loclist = true })
        end,
        desc = "[T]oggle [L]oclist",
      },
    },
    opts = {
      keys = {
        {
          ">",
          function()
            require("quicker").expand({
              before = 2,
              after = 2,
              add_to_existing = true,
            })
          end,
          desc = "Expand quickfix context",
        },
        {
          "<",
          function()
            require("quicker").collapse()
          end,
          desc = "Collapse quickfix context",
        },
      },
    },
  },
  {
    "olimorris/codecompanion.nvim",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "ravitemer/mcphub.nvim",
    },
    keys = {
      {
        "<leader>aa",
        "<cmd>CodeCompanionActions<cr>",
        mode = { "n", "v" },
        noremap = true,
        silent = true,
        desc = "[A]I [A]ctions",
      },
      {
        "<leader>ta",
        "<cmd>CodeCompanionChat Toggle<cr>",
        mode = { "n", "v" },
        noremap = true,
        silent = true,
        desc = "[T]oggle [A]I chat",
      },
      {
        "<leader>ac",
        "<cmd>CodeCompanionChat Add<cr>",
        mode = "v",
        noremap = true,
        silent = true,
        desc = "[A]I [C]hat add",
      },
    },
    opts = {
      strategies = {
        chat = {
          adapter = "copilot",
        },
        inline = {
          adapter = "copilot",
        },
      },
      extensions = {
        mcphub = {
          callback = "mcphub.extensions.codecompanion",
          opts = {
            make_vars = true,
            make_slash_commands = true,
            show_result_in_chat = true,
          },
        },
      },
    },
  },
  {
    "stevearc/oil.nvim",
    opts = {},
    lazy = false,
  },
}
