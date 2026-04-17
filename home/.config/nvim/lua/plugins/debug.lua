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
      }

      dap.configurations.c = dap.configurations.cpp
      dap.configurations.rust = dap.configurations.cpp
    end,
    dependencies = {
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
