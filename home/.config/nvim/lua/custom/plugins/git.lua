local map = require("mapper")

return {
  {
    'akinsho/git-conflict.nvim',
    opts = {
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
}
