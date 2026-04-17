return {
  {
    "akinsho/git-conflict.nvim",
    event = "BufRead",
    opts = {
      disable_diagnostics = true,
      default_mappings = {
        next = "]x",
        prev = "[x",
      },
    },
  },
  {
    "NeogitOrg/neogit",
    dependencies = {
      "nvim-lua/plenary.nvim",
    },
    keys = {
      {
        "<leader>go",
        function()
          require("neogit").open()
        end,
        desc = "neo[G]it [O]pen",
      },
    },
    cmd = "Neogit",
    opts = {
      disable_commit_confirmation = true,
      kind = "split",
      console_timeout = 5000,
      auto_show_console = false,
    },
  },
  {
    "ruifm/gitlinker.nvim",
    keys = {
      {
        "<leader>gy",
        function()
          require("gitlinker").get_buf_range_url("n")
        end,
      },
      {
        "<leader>gy",
        function()
          require("gitlinker").get_buf_range_url("v")
        end,
        mode = "v",
      },
    },
    dependencies = {
      "nvim-lua/plenary.nvim",
    },
    opts = {
      callbacks = {
        ["git.sommerfeld.dev"] = function(url_data)
          local url = require("gitlinker.hosts").get_base_https_url(url_data)
          url = url .. "/tree/" .. url_data.file .. "?id=" .. url_data.rev
          if url_data.lstart then
            url = url .. "#n" .. url_data.lstart
          end
          return url
        end,
      },
    },
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
      on_attach = function(bufnr)
        local gs = require("gitsigns")
        local function map(mode, l, r, desc)
          vim.keymap.set(mode, l, r, { buffer = bufnr, desc = desc })
        end
        local function nmap(l, r, desc)
          map("n", l, r, desc)
        end
        local function vmap(l, r, desc)
          map("v", l, r, desc)
        end
        -- Navigation
        nmap("]c", function()
          if vim.wo.diff then
            vim.cmd.normal({ "]c", bang = true })
          else
            gs.nav_hunk("next")
          end
        end, "Jump to next git [c]hange")

        nmap("[c", function()
          if vim.wo.diff then
            vim.cmd.normal({ "[c", bang = true })
          else
            gs.nav_hunk("prev")
          end
        end, "Jump to previous git [c]hange")

        -- Actions
        nmap("<leader>hs", gs.stage_hunk, "git [s]tage hunk")
        nmap("<leader>hr", gs.reset_hunk, "git [r]eset hunk")
        vmap("<leader>hs", function()
          gs.stage_hunk({ vim.fn.line("."), vim.fn.line("v") })
        end, "git [s]tage hunk")
        vmap("<leader>hr", function()
          gs.reset_hunk({ vim.fn.line("."), vim.fn.line("v") })
        end, "git [r]eset hunk")
        nmap("<leader>hS", gs.stage_buffer, "git [S]tage buffer")
        nmap("<leader>hR", gs.reset_buffer, "git [R]eset buffer")
        nmap("<leader>hp", gs.preview_hunk, "git [p]review hunk")
        nmap("<leader>hb", function()
          gs.blame_line({ full = true })
        end, "git [b]lame line")
        nmap(
          "<leader>tb",
          gs.toggle_current_line_blame,
          "[T]oggle git show [b]lame line"
        )
        nmap("<leader>hd", gs.diffthis, "git [d]iff against index")
        nmap("<leader>hD", function()
          gs.diffthis("~")
        end, "git [D]iff against last commit")
        nmap("<leader>hc", gs.change_base, "git [C]hange base to index")
        nmap("<leader>hC", function()
          gs.change_base("~")
        end, "git [C]hange base to HEAD")
        nmap(
          "<leader>tgd",
          gs.preview_hunk_inline,
          "[T]oggle [G]it show [D]eleted"
        )
        nmap("<leader>tgw", gs.toggle_word_diff, "[T]oggle [G]it [W]ord diff")
        nmap(
          "<leader>tgl",
          gs.toggle_linehl,
          "[T]oggle [G]it [L]ine highlighting"
        )
        -- Text object
        map(
          { "o", "x" },
          "ih",
          ":<C-U>Gitsigns select_hunk<CR>",
          "git [H]unk text object"
        )
      end,
    },
    dependencies = {
      "nvim-lua/plenary.nvim",
    },
  },
}
