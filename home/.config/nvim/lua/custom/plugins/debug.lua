return {
  {
    "miroshQa/debugmaster.nvim",
    branch = "dashboard",
    dependencies = "mfussenegger/nvim-dap",
    keys = {
      {
        "<leader>td",
        function()
          require("debugmaster").mode.toggle()
        end,
        desc = "[T]oggle [D]ebug mode",
      },
    },
  },
  {
    "mfussenegger/nvim-dap",
    config = function()
      local dap = require("dap")

      local function get_env_vars()
        local variables = vim.fn.environ()
        table.insert(variables, { ASAN_OPTIONS = "detect_leaks=0" })
        return variables
      end

      dap.adapters.lldb = {
        type = "executable",
        command = "lldb-dap",
        name = "lldb",
        env = get_env_vars,
      }
      dap.adapters.gdb = {
        type = "executable",
        command = "gdb",
        args = { "--interpreter=dap" },
        env = get_env_vars,
      }
      dap.adapters.codelldb = {
        type = "executable",
        command = "codelldb",
        env = get_env_vars,
      }

      local function get_program()
        local _program
        vim.ui.input({
          prompt = "Program: ",
          complete = "file_in_path",
        }, function(res)
          _program = res
        end)
        return vim.fn.system("which " .. _program):gsub("\n$", "")
      end

      local function get_args()
        local _args
        vim.ui.input({
          prompt = "Args: ",
          default = vim.fn.getreg("+"),
          complete = "file",
        }, function(res)
          _args = res
        end)
        return require("dap.utils").splitstr(_args)
      end

      dap.configurations.cpp = {
        -- {
        --   name = "GDB Launch",
        --   type = "gdb",
        --   request = "launch",
        --   cwd = "${workspaceFolder}",
        --   program = get_program,
        --   args = get_args,
        --   env = get_env_vars,
        --   stopAtBeginningOfMainSubprogram = false,
        -- },
        -- {
        --   name = "LLDB Launch",
        --   type = "lldb",
        --   request = "launch",
        --   cwd = "${workspaceFolder}",
        --   program = get_program,
        --   args = get_args,
        --   env = get_env_vars,
        --   stopOnEntry = true,
        --   disableASLR = false,
        -- },
        {
          name = "codelldb Launch",
          type = "codelldb",
          request = "launch",
          cwd = "${workspaceFolder}",
          program = get_program,
          args = get_args,
          stopOnEntry = true,
          console = "integratedTerminal",
        },
        -- {
        --   name = "GDB Attach to process",
        --   type = "gdb",
        --   request = "attach",
        --   pid = require('dap.utils').pick_process,
        -- },
        -- {
        --   name = "LLDB Attach to process",
        --   type = "lldb",
        --   request = "attach",
        --   pid = require('dap.utils').pick_process,
        -- },
        -- {
        --   name = "codelldb Attach to process",
        --   type = "codelldb",
        --   request = "attach",
        --   pid = require('dap.utils').pick_process,
        -- },
      }

      dap.configurations.c = dap.configurations.cpp
      dap.configurations.rust = dap.configurations.cpp

      -- local dapui = require("dapui")
      -- dap.listeners.before.attach.dapui_config = dapui.open
      -- dap.listeners.before.launch.dapui_config = dapui.open
      -- dap.listeners.before.event_terminated.dapui_config = dapui.close
      -- dap.listeners.before.event_exited.dapui_config = dapui.close

      -- local dv = require("dap-view")
      -- dap.listeners.before.attach["dap-view-config"] = dv.open
      -- dap.listeners.before.launch["dap-view-config"] = dv.open
      -- dap.listeners.before.event_terminated["dap-view-config"] = dv.close
      -- dap.listeners.before.event_exited["dap-view-config"] = dv.close
    end,
    dependencies = {
      -- {
      --   "igorlfs/nvim-dap-view",
      --   keys = {
      --     {
      --       "<leader>td",
      --       function()
      --         require("dap-view").toggle(true)
      --       end,
      --       desc = "[T]oggle [D]ebug UI",
      --     },
      --   },
      --   opts = {},
      -- },
      -- {
      --   "rcarriga/nvim-dap-ui",
      --   dependencies = "nvim-neotest/nvim-nio",
      --   keys = {
      --     {
      --       "<leader>td",
      --       function()
      --         require("dapui").toggle()
      --       end,
      --       desc = "[T]oggle [D]ebug UI",
      --     },
      --     {
      --       "<leader>de",
      --       function()
      --         require("dapui").eval()
      --       end,
      --       desc = "[D]ebug [E]valuate",
      --     },
      --   },
      --   opts = {
      --     icons = { expanded = "-", collapsed = "+", current_frame = "*" },
      --     controls = { enabled = false },
      --     layouts = {
      --       {
      --         elements = {
      --           -- Elements can be strings or table with id and size keys.
      --           "scopes",
      --           "breakpoints",
      --           "stacks",
      --           "watches",
      --         },
      --         size = 40,
      --         position = "left",
      --       },
      --       {
      --         elements = {
      --           "repl",
      --         },
      --         size = 0.25, -- 25% of total lines
      --         position = "bottom",
      --       },
      --     },
      --   },
      -- },
      {
        "theHamsta/nvim-dap-virtual-text",
        opts = {},
        dependencies = { "nvim-treesitter/nvim-treesitter" },
      },
      "williamboman/mason.nvim",
      {
        "jay-babu/mason-nvim-dap.nvim",
        opts = {
          automatic_installation = false,
          handlers = {},
          ensure_installed = {},
        },
      },
    },
  },
}
