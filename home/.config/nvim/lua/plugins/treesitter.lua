require("treewalker").setup({})

vim.keymap.set({ "n", "v" }, "<a-k>", "<cmd>Treewalker Up<cr>", { silent = true, desc = "Moves up to the previous neighbor node" })
vim.keymap.set({ "n", "v" }, "<a-j>", "<cmd>Treewalker Down<cr>", { silent = true, desc = "Moves up to the next neighbor node" })
vim.keymap.set({ "n", "v" }, "<a-h>", "<cmd>Treewalker Left<cr>", { silent = true, desc = "Moves to the first ancestor node that's on a different line from the current node" })
vim.keymap.set({ "n", "v" }, "<a-l>", "<cmd>Treewalker Right<cr>", { silent = true, desc = "Moves to the next node down that's indented further than the current node" })
vim.keymap.set("n", "<s-a-k>", "<cmd>Treewalker SwapUp<cr>", { silent = true, desc = "Swaps the highest node on the line upwards in the document" })
vim.keymap.set("n", "<s-a-j>", "<cmd>Treewalker SwapDown<cr>", { silent = true, desc = "Swaps the biggest node on the line downward in the document" })
vim.keymap.set("n", "<s-a-h>", "<cmd>Treewalker SwapLeft<cr>", { silent = true, desc = "Swap the node under the cursor with its previous neighbor" })
vim.keymap.set("n", "<s-a-l>", "<cmd>Treewalker SwapRight<cr>", { silent = true, desc = "Swap the node under the cursor with its next neighbor" })

require("nvim-treesitter").install({
  "awk",
  "bash",
  "c",
  "cmake",
  "comment",
  "cpp",
  "css",
  "csv",
  "diff",
  "dockerfile",
  "doxygen",
  "editorconfig",
  "fortran",
  "git_config",
  "git_rebase",
  "gitattributes",
  "gitcommit",
  "gitignore",
  "groovy",
  "gpg",
  "hlsplaylist",
  "html",
  "http",
  "ini",
  "javascript",
  "jq",
  "jsdoc",
  "json",
  "just",
  "llvm",
  "lua",
  "luadoc",
  "luap",
  "make",
  "markdown",
  "markdown_inline",
  "query",
  "passwd",
  "printf",
  "python",
  "regex",
  "readline",
  "requirements",
  "rust",
  "sql",
  "ssh_config",
  "strace",
  "sxhkdrc",
  "tablegen",
  "todotxt",
  "toml",
  "typescript",
  "vim",
  "vimdoc",
  "xcompose",
  "xml",
  "xresources",
  "yaml",
})

require("nvim-dap-repl-highlights").setup({})
require("treesitter-context").setup({})

require("ts_context_commentstring").setup({
  enable_autocmd = false,
})
local get_option = vim.filetype.get_option
vim.filetype.get_option = function(filetype, option)
  return option == "commentstring"
      and require("ts_context_commentstring.internal").calculate_commentstring()
    or get_option(filetype, option)
end
