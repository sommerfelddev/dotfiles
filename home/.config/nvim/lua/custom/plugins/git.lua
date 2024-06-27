local map = require("mapper")

return {
  {
    'akinsho/git-conflict.nvim',
    opts = {
      disable_diagnostics = true,
      highlights = {
        current = nil,
        incoming = nil,
        ancestor = nil,
      },
      default_mappings = {
        next = ']x',
        prev = '[x',
      },
    }
  },
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
          ["git.sommerfeld.dev"] = function(url_data)
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
      _threaded_diff = true,
      _refresh_staged_on_update = true,
      on_attach = function(bufnr)
        local gs = require('gitsigns')

        -- Navigation
        map.n(']c', function()
          if vim.wo.diff then
            vim.cmd.normal({ ']c', bang = true })
          else
            gs.nav_hunk('next')
          end
        end, nil, bufnr)

        map.n('[c', function()
          if vim.wo.diff then
            vim.cmd.normal({ '[c', bang = true })
          else
            gs.nav_hunk('prev')
          end
        end, nil, bufnr)

        -- Actions
        map.n('<leader>hs', gs.stage_hunk, nil, bufnr)
        map.n('<leader>hr', gs.reset_hunk, nil, bufnr)
        map.v('<leader>hs', function() gs.stage_hunk { vim.fn.line('.'), vim.fn.line('v') } end, nil, bufnr)
        map.v('<leader>hr', function() gs.reset_hunk { vim.fn.line('.'), vim.fn.line('v') } end, nil, bufnr)
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
}
