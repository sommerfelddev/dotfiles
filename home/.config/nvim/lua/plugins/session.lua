return {
  {
    "rmagatti/auto-session",
    lazy = false,
    opts = function()
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
              nil,
              { on_conflict = "overwrite" }
            )
          end,
        },
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
}
