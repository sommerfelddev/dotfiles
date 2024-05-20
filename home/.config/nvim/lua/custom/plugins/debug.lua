local map = require("mapper")

return {
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
}
