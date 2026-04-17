return {
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
}
